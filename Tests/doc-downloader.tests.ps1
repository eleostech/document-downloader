$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1

$BASE_URI = 'https://359c4f0b-d5b7-459f-9997-dbebf9369b15.mock.pstmn.io'

$testfile = ($here + "\TestFile.log")

if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
}

$DRIVE_AXLE = $false # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "Placeholder"

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) 
                         Accept = 'application/json'}

$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY)
                    Accept = 'application/json'}

$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }

Describe "Helper Function Tests" {
    Context 'Verifying helper functions produce correct output' {
        it 'CreateLogFile should produce a log filename corresponding to todays date' {
            $CurrentTime = Get-Date -Format yyyy-MM-dd
            $filename = ("Eleos-" + ($CurrentTime + ".log"))
            $path = $src + "\Tests\" + $filename
            $filepath  = CreateLogFile $path
            Test-Path $filepath | should be $true 
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
            $response.StatusCode | should not be 304
            }

         it 'GetNextDoc should return a 500 if there is a server error' {
                $request  =  $BASE_URI + '/api/v1/documents/queued/next/badserver'
                try{
                    $request = GetNextDoc $request $HEADERS $testfile -ErrorAction SilentlyContinue 
                } 
                catch {
                    $_.CategoryInfo.Reason | Should be 'WebException' 
                }
        }
    }

    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 302 with URL and filename to download document' {
            $request = $BASE_URI
            $response = GetDocFromQueue $request $HEADERS $testfile
            $response | should not be $null
        }
        it 'GetDocFromQueue should return a 404 if document could not be found' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
                try{
                    $request = GetNextDoc $request $HEADERS $testfile -ErrorAction SilentlyContinue 
                } 
                catch {
                    $_.CategoryInfo.Reason | Should be 'WebException' 
                }
        }
    }
    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $request = $BASE_URI + '/api/v1/documents/queued/' + $GlobalDocID.ToString()
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $response = $response | ConvertFrom-Json
            $response.message | Should be "Document Downloaded Successfully"
        }
        it 'RemoveDocFromQueue should return a 404 if the document to be removed could not be found' {
            $request = $BASE_URI + '/api/v1/documents/queued/1000000000'
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $response | should be $null
        }
    }
    Context 'Testing ExponentialDeleteRetry function' {
        it 'ExpWait should return a null if the document is never removed after the multiple retires due to 404 not found' {
            $request = $BASE_URI + '/api/v1/documents/queued/100000000000'
            $response = ExponentialDeleteRetry $request $Headers $testfile
            $response | should be $null
        }
    }
}