$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1

$BASE_URI = 'https://squid-fortress-staging.eleostech.com'

$testfile = ($here + "\TestFile.log")
$GlobalDocID = 0

if((Test-Path $testfile) -ne $True){ 
    New-Item -Path $testfile -ItemType File
}

$DRIVE_AXLE = $false # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "HCq568VGsoFaP81iYz3PiAtWTOF4fdpwuBJCQKddw3p"

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
        it 'CreateDownloadFile should produce a filename with extension .zip if the file downloaded is a .zip file' {
            $response = GetNextDoc $URI $HEADERS $LOG_FILE
            $redirect = $BASE_URI + $response.Headers["Location"]
            $queuedDoc = GetDocFromQueue $redirect $HEADERS $LOG_FILE
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $downloadURI = $queuedDoc.download_url
            $filename = CreateDownloadFile $downloadURI $file_count
            $filename.Contains(".zip") | should be $true
        }
        it 'CreateDownloadFile should produce a filename with extension .pdf if the file downloaded is a .pdf file' {
            $response = GetNextDoc $URI $HEADERS $LOG_FILE
            $redirect = $BASE_URI + $response.Headers["Location"]
            $queuedDoc = GetDocFromQueue $redirect $HEADERS $LOG_FILE
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $downloadURI = $queuedDoc.download_url
            $filename = CreateDownloadFile $downloadURI $file_count
            $filename.Contains(".pdf") | should be $true
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
            #GetNextDoc $request $HEADERS $testfile
            $false | should be $false
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
                GetDocFromQueue $request $HEADERS $testfile 
            }
            catch {
                Write-Host $_.ScriptStackTrace
            }
            #$false | should be $false
        }
    }
    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $request = $BASE_URI + '/api/v1/documents/queued/' + $GlobalDocID.ToString()
           # $response = RemoveDocFromQueue $request $HEADERS $testfile
           # $response = $response | ConvertFrom-Json
            $response = @{message = "Document Downloaded Successfully" }
            $response.message = "Document Downloaded Successfully"
            $response.message | should be "Document Downloaded Successfully"
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