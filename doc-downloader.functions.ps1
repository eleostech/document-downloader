#----------------------------------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------------------------------

function CreateLogFile
{param([string]$Dir)
    $CurrentTime = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + ($CurrentTime + ".log"))
    $filepath = ($DIR + $filename)
    return $filepath
}

function CreateDownloadFile 
{param([string] $downloadURI, [int32] $file_count)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd_HH:mm"

    if($downloadURI.Contains(".zip")){
        $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.zip')
    }
    elseif ($downloadURI.Contains(".pdf")){
        $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.pdf')
    }
    elseif ($downloadURI.Contains(".tif")){
        $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.tif')
    }

    elseif ($downloadURI.Contains(".png")){
        $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.png')
    }
    elseif ($downloadURI.Contains(".jpg")){
        $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.jpg')
    }
    return $filename
} 

function WriteToLog
{param([string]$TextToWrite, [string]$file)  
    $TextToWrite | Out-File $file -Append
}

function CheckDirectory
{param([string]$Dir)
    if(-not (Test-Path $Dir)){
        new-item $Dir -itemtype directory
    }
}

function  MakeHttpGetCall
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable $ProcessError
    if($ProcessError){
        WriteToLog $ProcessError
    }
    return $response
}


function  MakeHttpDeleteCall 
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -Method Delete
        return $response
    }
    catch{
        return $null
    }
}

function ExponentialDeleteRetry
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $MAX_ATTEMPTS = 5
    $attempts = 1
    $MAX_BACKOFF = 16
    $curr_backoff = 1
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    for($i = $attempts; $i -lt $MAX_ATTEMPTS; $i++){
        $response = MakeHttpDeleteCall $URI $HEADERS $LOG_FILE
        If ($response){
            return $response
        }
        else{
            $offset = (Get-Random -Maximum 3000) / 1000
            Start-Sleep -Seconds ($curr_backoff + $offset)
        }
        If($curr_backoff -lt $MAX_BACKOFF){
            $curr_backoff = $curr_backoff * 2
        }
    }
    $Timer.Stop()
    WriteToLog ("Process failed after " + $MAX_ATTEMPTS.ToString() + ' attempts' +"`r`n" + 'Time:' + $Timer.Elapsed.ToString() + "s " + "`r`n") $LOG_FILE
    return $null
}


function ExtractFilenameFromHeader
{param ([string]$downloadURI, [int32]$file_count, [string]$log_file)
    $WebRequest = [System.Net.WebRequest]::Create($downloadURI)
    try {
        $WebRequest.Timeout = 5000
        $Response = $WebRequest.GetResponse()
        $dispositionHeader = $Response.Headers['Content-Disposition']
        $disposition = [System.Net.Mime.ContentDisposition]::new($dispositionHeader)
        $Response.Dispose()
        $file = $disposition.FileName
        return $file
    }
    catch {
        WriteToLog ($_."An exception has occured: " + $_.Exception.Message + "`r`n") $log_file
        $file = (CreateDownloadFile $downloadURI $file_count)
        WriteToLog ("filename generated from $downloadURI : $file`r`n") $log_file
        return $file
    }
}

function GetFilename
<<<<<<< HEAD
{param ([string] $downloadURI, [int32]$file_count, [string]$log_file)
    $WebRequest = [System.Net.WebRequest]::Create($downloadURI)
    $Response = $WebRequest.GetResponse()
    $contentDisposition = $Response.Headers['Content-Disposition']
    if($contentDisposition -and $contentDisposition.Contains("attachment; filename=")){
        return ExtractFilenameFromHeader $downloadURI $file_count $log_file
=======
{ param ([string] $downloadURI, [int32]$file_count)
    $content = wget $downloadURI
    $contentDisposition = $content.Headers.'Content-Disposition'
    if($contentDisposition -and $contentDisposition.Contains("filename=")){
        $contentDisposition = $content.Headers.'Content-Disposition'
        return ExtractFilenameFromHeader $contentDisposition
>>>>>>> parent of 3761514 (Changing some logic in GetFilename)
    }
    else {
        return CreateDownloadFile $downloadURI $file_count
    }
}

#----------------------------------------------------------------------------------------------------------
# Eleos API Consumer Functions
#----------------------------------------------------------------------------------------------------------

function GetNextDoc
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = MakeHttpGetCall $URI $HEADERS $LOG_FILE
    return $response   
}

function GetDocFromQueue
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = MakeHttpGetCall $URI $HEADERS $LOG_FILE
    return $response
}

function RemoveDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = MakeHttpDeleteCall $URI $HEADERS $LOG_FILE
    if($response -eq $null){           
        WriteToLog ("Error Removing Document. Trying again... `r`n") $LOG_FILE
        $retry = ExponentialDeleteRetry $redirect $HEADERS $LOG_FILE
        If($retry){
            WriteToLog ("Document Removed from Queue with Status Code: " + $retry.StatusCode + "`r`n") $LOG_FILE 
        }
        Else{
            WriteToLog ("Error Removing Document after retry`r`n") $LOG_FILE
        }
        return $retry
    }
    return $response
}
