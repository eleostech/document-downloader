$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1
$proj = Split-Path -Path $src -Parent


$BASE_URI = 'https://localhost:44373'

$testfile = ($here + "\LogFile.txt")

if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
}

$API_KEY = "Placeholder"

$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY)
                    Accept = 'application/json'}

$HEADERS =  $ELEOS_HEADERS

Describe "Helper Function Tests" {
    Context 'Verifying helper functions produce correct output' {
        it 'CreateLogFile should produce a log filename corresponding to todays date' {
            $CurrentDate = Get-Date -Format yyyy-MM-dd
            $filename = ("Eleos-" + ($CurrentDate + ".log"))
            $path = $src + "\Tests\" + $filename
            $filepath  = CreateLogFile $path
            Test-Path $filepath | should be $true 
            Get-ChildItem ($src + '\Tests\*log')  | ForEach-Object {Remove-Item $_}
        }
  
        it 'CreateDownloadFile should produce filename with correct extension' { 
            $URI = $BASE_URI + '/api/v1/documents/queued/1'
            $queuedDoc = GetDocFromQueue $URI $HEADERS $LOG_FILE
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $filename = CreateDownloadFile $queuedDoc.downloadUrl $file_count
            $filename.Contains(".jpg") | should be $true
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
            $request = $BASE_URI + '/api/v1/documents/queued/next/empty'
            $response = GetNextDoc $request $HEADERS $testfile
            $response.StatusCode | should be 304
        }

        it 'GetNextDoc should throw an expection if a 404 status code is returned' {
            $request = $BASE_URI + '/api/v1/documents/queued/next/fail'
            $exception = $false
            try {
                $response = GetNextDoc $request $HEADERS $testfile
            }
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should be $true
        }


        it 'GetNextDoc should throw an exception if a 500 status code is returned' {
            $request  =  $BASE_URI + '/api/v1/documents/queued/next/badserver'
            $exception = $false
            try{
                $request = GetNextDoc $request $HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq "WebException"
            }
            $exception | Should be $true
        }
    }

    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 200 with a URL to download document' {
            $request = $BASE_URI + '/api/v1/documents/queued/1'
            $response = GetDocFromQueue $request $HEADERS $testfile
            $response.StatusCode | should be 200
            $response = $response | ConvertFrom-Json
            $response.downloadUrl | should not be $null
        }

        it 'GetDocFromQueue should throw an exception if a 404 status code is returned' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $exception = $false
            try{
                $request = GetNextDoc $request $HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should be $true
        }

        it 'GetDocFromQueue should throw an exception if a 500 status code is returned' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $exception = $false
            try{
                $request = GetNextDoc $request $HEADERS $testfile -ErrorAction SilentlyContinue 
            } 
            catch {
                $exception = $_.CategoryInfo.Reason -eq 'WebException' 
            }
            $exception | Should be $true
        }
    }

    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $request = $BASE_URI + '/api/v1/documents/queued/1'
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $response = $response | ConvertFrom-Json
            $response.message | Should be "Document deleted successfully."
        }
        it 'RemoveDocFromQueue should return null if the document to be removed could not be found' {
            $request = $BASE_URI + '/api/v1/documents/queued/2'
            $response = RemoveDocFromQueue $request $HEADERS $testfile
            $response | should be $null
        }
    }
    
    Context 'Testing ExponentialDeleteRetry function' {
        it 'ExpWait should return a null if the document is never removed after the multiple retires due to 404 not found' {
            $request = $BASE_URI + '/api/v1/documents/queued/3'
            $response = ExponentialDeleteRetry $request $Headers $testfile
            $response | should be $null
        }
    }
}