$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1


$BASE_URI = 'https://localhost:44373'

$testfile = ($here + "\LogFile.txt")

if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
}

$API_KEY = "Placeholder"

$HEADERS = @{ Authorization = ("key=" + $API_KEY)
                    Accept = 'application/json'}


Describe "Helper Function Tests" {
    Context 'Verifying helper functions produce correct output' {
        it 'CreateLogFile should produce a log filename corresponding to todays date' {
            $path = $src + "\Tests\"
            $filepath  = CreateLogFile $path
            $filepath -like ($path + "Eleos-*log") | Should be $true
        }
  
        it 'CreateDownloadFile should produce filename with correct extension(jpg)' { 
            $URI = $BASE_URI + '/api/v1/documents/queued/1'
            $queuedDoc = GetDocFromQueue $URI $HEADERS $LOG_FILE
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $filename = CreateDownloadFile $queuedDoc.downloadUrl $file_count
            $filename.Contains(".jpg") | should be $true
        }

        it 'ExtractFilenameFromHeader should produce a string that matches the name of file in Content-Dispostion' {
            $downloadURI = $BASE_URI + "/api/download/validHeader"
            $filename = ExtractFilenameFromHeader $downloadURI
            $filename | Should be 'filename.jpg'
        }
        it 'ExtractFilenameFromHeader should only produce a string that matches the filename' {
            $downloadURI = $BASE_URI + "/api/download/validHeader"
            $filename = ExtractFilenameFromHeader $downloadURI
            $ContainsNonFileNameStrings = !($filename.Contains('filename="') -and $filename.Contains('attachment;'))
            $ContainsNonFileNameStrings | Should be $true
        }

        it 'ExtractFilenameFromHeader should produce a string that matches a filename if the filename has delimeters'{
            $downloadURI = $BASE_URI + "/api/download/multipledelimeter"
            $filename = ExtractFilenameFromHeader $downloadURI
            $filename | Should be "_NA__NA__; 2020-09.zip"
        }

        it 'GetFilename should not crash and return a filename if Content-Disposition header does not exist' {
            $downloadURI = $BASE_URI + '/api/download/mock_server_file.png'
            $filename = GetFilename $downloadURI 1 $testfile
            $filename -like "Eleos-*png" | Should be $true
        }
        it 'GetFilename should not crash and return a filename called Eleos-<Date and time>.tif' {
            $downloadURI = $BASE_URI + '/api/content-disp/somefile.tif'
            $filename = GetFilename $downloadURI 0 $testfile
            $filename -like "Eleos-*tif"| Should be $true
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
                GetNextDoc $request $HEADERS $testfile
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
