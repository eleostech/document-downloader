$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1

$BASE_URI = 'https://359c4f0b-d5b7-459f-9997-dbebf9369b15.mock.pstmn.io'

$testfile = ($here + "\testlog.log")

if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
    }

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) }
$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY) }
$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }


Describe "Helper Function Tests" {
    Context 'Verifying helper functions produce correct output' {
        it 'CreateTimestamp should produce correct date and time' {
            $Timestamp = Get-Date -format "dd-MMM-yyyy HH:mm"
            mock -CommandName Get-Date -MockWith { $Timestamp }
            CreateTimestamp | should be $Timestamp
        }
        it 'CreateLogFile should produce a log filename corresponding to todays date' {
            $CurrentTime = Get-Date -Format yyyy-MM-ddTHH
            mock -CommandName Get-Date -MockWith { $CurrentTime }
            $filename = ("Eleos-" + ($CurrentTime + ".log"))
            CreateLogFile "C:\Eleos\" | should be $filename
        }
    }
}


Describe "Consume API Function Tests" {
    Context 'Testing GetNextDoc function' {
        it 'GetNextDoc should return a 302 if there is a document in the queue' {
            $request = $BASE_URI + '/api/v1/documents/queued/next'
            $response = GetNextDoc $request $HEADERS $testfile
            $response.StatusCode | should be 302
        }
        it 'GetNextDoc should return a 304 if there is not a document in the queue' {
            $request = $BASE_URI + '/api/v2/documents/queued/next'
            $response = GetNextDoc $request $HEADERS $testfile
            }

         it 'GetNextDoc should return a 500 if there is a server error' {
            $request  =  $BASE_URI + '/api/v1/documents/queued/next/badserver'
            GetNextDoc $request $HEADERS $testfile | should Throw
            }
        }
    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 302 with URL and filename to download document' {
            $request = $BASE_URI + '/api/v1/documents/queued/3'
            $response = GetDocFromQueue $request $HEADERS $testfile
            $response = $response | ConvertFrom-Json
            $response.document_identifier | should not be $null
        }
        it 'GetDocFromQueue should return a 404 if document could not be found' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $repsonse = GetDocFromQueue $request $HEADERS $testfile | should throw 
            $false | should be $false
        }
    }
    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $request = $BASE_URI + '/api/v1/documents/queued/1'
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $response = $response | ConvertFrom-Json
            $response.message | should be "Document Downloaded Successfully"
        }
        it 'RemoveDocFromQueue should return a 404 if the document to be removed could not be found' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $false | should be $false
        }
    }
    Context 'Testing ExpWait function' {
        it 'ExpWait should return a null if the document is never removed after the wait due to 404 not found' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $repsonse = ExpWait $request $Headers 1.001 $testfile
            $response | should be $null
            }
    }
          
}

Remove-Item "C:\Eleos\*.log"