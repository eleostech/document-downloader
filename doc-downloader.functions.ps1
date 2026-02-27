#----------------------------------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------------------------------

function CreateLogFile
{param([string]$Dir)
    $CurrentTime = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + ($CurrentTime + ".log"))
    $filepath = Join-Path -Path $Dir -ChildPath $filename
    return $filepath
}

function WriteToLog
{param([string]$TextToWrite, [string]$file)
    $powershellVersion = (Get-Host).Version.Major
    if($powershellVersion -ge 7){
        $TextToWrite | Out-File -FilePath $file -Append
    }
    else {
        $TextToWrite | Out-File $file -Append
    }
}

function CheckDirectory
{param([string]$Dir)
    if(-not (Test-Path $Dir)){
        new-item $Dir -itemtype directory
    }
}

function  MakeHttpGetCall
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $ProgressPreference = 'SilentlyContinue'
    $powershellVersion = (Get-Host).Version.Major
    try{
        if($powershellVersion -ge 7){
            $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue
        }
        else {
            try {
                $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction Stop
            } catch {
                if ($_.Exception.Response -and ($_.Exception.Response.StatusCode -eq 302 -or $_.Exception.Response.StatusCode -eq 304)) {
                    $response = $_.Exception.Response
                } else {
                    throw $_
                }
            }
        }
        
        if ($response.StatusCode -ge 400) {
            Write-Host "HTTP Error: $($response.StatusCode) for URI: $URI"
            throw [System.Net.WebException]::new("WebException")
        }
        return $response
    }
    catch{
        Write-Host "Caught Exception: $($_.Exception.Message)"
        if ($_.Exception -is [System.Net.WebException]) {
            if($LOG_FILE){ WriteToLog $_.Exception.Message $LOG_FILE }
            throw $_
        }
        if($LOG_FILE){ WriteToLog $_.Exception.Message $LOG_FILE }
        throw [System.Net.WebException]::new($_.Exception.Message)
    }
}


function  MakeHttpDeleteCall
{param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $ProgressPreference = 'SilentlyContinue'
        $powershellVersion = (Get-Host).Version.Major
        if($powershellVersion -ge 7){
            $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -Method Delete -SkipHttpErrorCheck -ErrorAction SilentlyContinue
        }
        else {
            $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -Method Delete -ErrorAction SilentlyContinue
        }

        if ($response.StatusCode -ge 400) {
            return $null
        }
        return $response
    }
    catch{
        if($LOG_FILE){ WriteToLog $_.Exception.Message $LOG_FILE }
        return $null
    }
}

function DownloadFile
{param([string]$URI, [string]$FileName, [string]$OutFilePath, [string]$LOG_FILE)
  try {
    $response = Invoke-WebRequest -Uri $URI -OutFile (Join-Path $OutFilePath $FileName)
    WriteToLog ("File " + $FileName + "  downloaded successfully to " + $OutFilePath) $LOG_FILE
  } catch {
    if($_.Exception.Response.StatusCode.Value__.ToString() -like '4**') {
      WriteToLog("Error while downloading document, status code: " + $_.Exception.Response.StatusCode.Value__.ToString() + ". The document may have already been purged, moving onto next document...") $LOG_FILE
    }
    else {
      throw $_
    }
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

function GetFilename
{param ([string] $downloadURI, [int32]$file_count, [string]$log_file)
    try{
        return ExtractFilenameFromHeader $downloadURI $file_count $log_file
    }
    catch {
        WriteToLog ("An exception has occured: " + $_.Exception.Message + "`r`n") $log_file
        return CreateDownloadFile $downloadURI $file_count
    }
}

function ExtractFilenameFromHeader
{param ([string]$downloadURI, [int32]$file_count, [string]$log_file)
    $WebRequest = [System.Net.WebRequest]::Create($downloadURI)
    $WebRequest.Timeout = 10000
    $Response = $WebRequest.GetResponse()
    $dispositionHeader = $Response.Headers['Content-Disposition']
    $disposition = [System.Net.Mime.ContentDisposition]::new($dispositionHeader)
    $Response.Dispose()
    $file = $disposition.FileName
     return $file
}

function CreateDownloadFile 
{param([string] $downloadURI, [int32] $file_count)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd_HH:mm"
    $index = $downloadURI.IndexOf("filename");
    $extension = ".zip" # Default

    if ($index -ge 0) {
        $sub = $downloadURI.Substring($index, ($downloadURI.Length - $index))
        $subList = $sub.Split("%")

        foreach ($element in $subList) {
            if($element -like "*.*") {
                $e_index = $element.lastIndexOf(".")
                $extension = $element.Substring($e_index, $element.Length - $e_index)
                break
            }
        }
    }

    $filename = "Eleos-" + $CurrentDate + "_" + $file_count + $extension
    return $filename
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
        $retry = ExponentialDeleteRetry $URI $HEADERS $LOG_FILE
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
