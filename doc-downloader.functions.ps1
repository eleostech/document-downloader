#----------------------------------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------------------------------

function CreateTimestamp
{
    $Timestamp = Get-Date -format "dd-MMM-yyyy HH:mm"
    return $Timestamp
}

function CreateLogFile
{
    param([string]$Dir)
    $CurrentTime = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + ($CurrentTime + ".log"))
    $filepath = ($DIR + $filename)
    if((Test-Path $filepath) -ne $True){
        New-Item -Path $filepath -ItemType File
    }
    return $filepath;
}

function WriteToLog
{ param([string]$TextToWrite, [string]$file)
    
    $TextToWrite | Out-File $file -Append
}

function CheckDirectory
{ param([string]$Dir)
    if (-not (Test-Path $Dir))
    {
        new-item $Dir -itemtype directory
    }
}

function ExpWait
{ param([string]$URI, [hashtable]$HEADERS, [int32]$currBackoff, [string]$LOG_FILE)
    $MAX_BACKOFF = 32
    if($currBackoff -ge $MAX_BACKOFF){
    WriteToLog ("Process failed after  " + $currBackoff + "s " + "`r`n")
      return $response.StatusCode
    }

    #generates random amount of miliseconds to wait
    $rand_milisec = ((Get-Random -Maximum 3000) + 1)/1000

    #Wait time before retrying 
    $currBackoff += $rand_milisec

    Start-Sleep -Seconds $currBackoff

    $response = RemoveDocFromQueue $URI $HEADERS
    If ($response.StatusCode -eq 200){
        return $response.StatusCode
    }
    Else {
        WriteToLog ("Error Removing Document: Response returned " + $repsonse.StatusCode + ". Tried after " + $currBackoff + " seconds " + "`r`n")
        ExpWait($URI, $HEADERS, $currBackoff * $currBackoff)
    }
}

#----------------------------------------------------------------------------------------------------------
# Eleos API Consumer Functions
#----------------------------------------------------------------------------------------------------------

function GetNextDoc
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable $ProcessError
        if($ProcessError){
            WriteToLog $ProcessError
        }
        return $response
        }
        catch{
            WriteToLog $_.Exception.Message $LOG_FILE
            return $false
        }  
             
}

function GetDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable $ProcessError
        if($ProcessError) {
            WriteToLog $ProcessError
        }
        return $response
    }
    catch{
        WriteToLog $_.Exception.Message $LOG_FILE
        return $false
    }
}

function RemoveDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $response = Invoke-WebRequest -Uri $URI -Method DELETE -Headers $HEADERS
    }
    catch {
        WriteToLog $_.Exception.Message $LOG_FILE
        return $false
    }
}
