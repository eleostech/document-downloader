$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1

$testfile = ($here + "\LogFile.txt")

$API_KEY = "api-keys-are-cool"
$BASE_URL = 'http://localhost:5000'
$DRIVE_AXLE_HEADERS = @{ Authorization = ("DriveAxleKey key=" + $API_KEY)
                         Accept = 'application/json'}
                
if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
}

Describe "Consume API Function Tests" {    
    Context 'Testing GetNextDoc function' {
        it 'GetNextDoc should return a 302 if there is a document in the queue' {
            $request = $BASE_URL + '/api/v1/documents/queued/next'
            $response = GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile
            $response.StatusCode | should -Be 302
        }
        it 'GetNextDoc should return a 304 if there is not a document in the queue' {
            $request = $BASE_URL + '/api/v1/documents/queued/next/empty'
            $response = GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile
            $response.StatusCode | should -Be 304
        }

        it 'GetNextDoc should throw an expection if a 404 status code is returned' {
            $request = $BASE_URL + '/api/v1/documents/queued/next/fail'
            $exception = $false
            try {
                GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile
            }
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should -Be $true
        }


        it 'GetNextDoc should throw an exception if a 500 status code is returned' {
            $request  =  $BASE_URL + '/api/v1/documents/queued/next/badserver'
            $exception = $false
            try{
                $request = GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq "WebException"
            }
            $exception | Should -Be $true
        }
    }

    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 200 with a URL to download document' {
            $request = $BASE_URL + '/api/v1/documents/queued/1'
            $response = GetDocFromQueue $request $DRIVE_AXLE_HEADERS $testfile
            $response.StatusCode | should -Be 200
            $response = $response | ConvertFrom-Json
            $response.downloadUrl | should -Not -Be $null
        }

        it 'GetDocFromQueue should throw an exception if a 404 status code is returned' {
            $request = $BASE_URL + '/api/v1/documents/queued/2'
            $exception = $false
            try{
                $request = GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should -Be $true
        }

        it 'GetDocFromQueue should throw an exception if a 500 status code is returned' {
            $request = $BASE_URL + '/api/v1/documents/queued/2'
            $exception = $false
            try{
                $request = GetNextDoc $request $DRIVE_AXLE_HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should -Be $true
        }
    }

    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $request = $BASE_URL + '/api/v1/documents/queued/1'
            $response = RemoveDocFromQueue $request $DRIVE_AXLE_HEADERS $testfile
            $response = $response | ConvertFrom-Json
            $response.message | Should -Be "Document deleted successfully."
        }
        it 'RemoveDocFromQueue should return null if the document to be removed could not be found' {
            $request = $BASE_URL + '/api/v1/documents/queued/2'
            $response = RemoveDocFromQueue $request $DRIVE_AXLE_HEADERS $testfile
            $response | should -Be $null
        }
    }
    
    Context 'Testing ExponentialDeleteRetry function' {
        it 'ExpWait should return a null if the document is never removed after the multiple retires due to 404 not found' {
            $request = $BASE_URL + '/api/v1/documents/queued/3'
            $response = ExponentialDeleteRetry $request $DRIVE_AXLE_HEADERS $testfile
            $response | should -Be $null
        }
    }
}


