$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\doc-downloader.functions.ps1

$baseURI = 'https://359c4f0b-d5b7-459f-9997-dbebf9369b15.mock.pstmn.io'

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
            CreateLogFile | should be $filename
        }
    }
}


Describe "Consume API Function Tests" {
    Context 'Testing GetNextDoc function' {
        it 'GetNextDoc should return a 302 if there is a document in the queue' {
            $response = $true
            $response | should be $true
        }
        it 'GetNextDoc should return a 304 if there is not a document in the queue' {
            $request = $baseURI + '/api/v1/documents/queued/next'
            $response = GetNextDoc $request $HEADERS
            $response | should not be $null
            }
         it 'GetNextDoc should return a 500 if there is a server error' {
            $request  =  $baseURI + '/api/v1/documents/queued/next/badserver'
            $response = GetNextDoc $request $HEADERS

            }
        }
    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 302 with URL and filename to download document' {
            $response = $true
            $response | should be $true
        }
        it 'GetDocFromQueue should return a 404 if document could not be found' {
            $request = $baseURI + '/api/v1/documents/queued/2'
            $response = GetNextDoc $request $HEADERS
            $response | should be $true
        }
    }
    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $response = $true
            $response | should be $true
        }
        it 'RemoveDocFromQueue should return a 404 if the document to be removed could not be found' {
            $response = $true
            $response | should be $true
        }
    }
}