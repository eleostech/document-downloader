#----------------------------------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------------------------------

function CreateLogFile
{param([string]$Dir)
    $CurrentTime = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + ($CurrentTime + ".log"))
    $filepath = ($DIR + $filename)
    if((Test-Path $filepath) -ne $True){
        New-Item -Path $filepath -ItemType File
    }
    return $filepath
}

function CreateDownloadFile 
{ param([int32] $file_count)
    $CurrentDate = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + $CurrentDate.ToString() + '_' + $file_count.ToString() + '.zip')
    return $filename
} 

function WriteToLog
{ param([string]$TextToWrite, [string]$file)  
    $TextToWrite | Out-File $file -Append
}

function CheckDirectory
{ param([string]$Dir)
    if (-not (Test-Path $Dir)){
        new-item $Dir -itemtype directory
    }
}

function  MakeHttpGetCall
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue -ErrorVariable $ProcessError
    if($ProcessError){
        WriteToLog $ProcessError
    }
    return $response
}


function  MakeHttpDeleteCall 
{  param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    try{
        $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 
        return $response
    }
    catch {
        return $null
    }
}

function ExponentialDeleteRetry
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $MAX_ATTEMPTS = 5
    $attempts = 1
    $MAX_BACKOFF = 10
    $curr_backoff = 2
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
        If ($curr_backoff -lt $MAX_BACKOFF){
            $curr_backoff = [Math]::Pow($curr_backoff,2)
        }
    }
    $Timer.Stop()
    WriteToLog ("Process failed after " + $MAX_ATTEMPTS.ToString() + ' attempts' +"`r`n" + 'Time:' + $Timer.Elapsed.ToString() + "s " + "`r`n") $LOG_FILE
    return $null
}

#----------------------------------------------------------------------------------------------------------
# Eleos API Consumer Functions
#----------------------------------------------------------------------------------------------------------

function GetNextDoc
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $response = MakeHttpGetCall $URI $HEADERS $LOG_FILE
    return $response   
}

function GetDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
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
