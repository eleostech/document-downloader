#----------------------------------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------------------------------

function CreateLogFile
{
    param([string]$Dir)
    $CurrentTime = Get-Date -Format yyyy-MM-dd
    $filename = ("Eleos-" + ($CurrentTime + ".log"))
    $filepath = ($DIR + $filename)
    if((Test-Path $filepath) -ne $True){
        New-Item -Path $filepath -ItemType File
    }
    return $filepath
}

function CreateDownloadFile 
{
    param([int32] $file_count)
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
    if (-not (Test-Path $Dir))
    {
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


function ExponentialDeleteRetry
{ param([string]$URI, [hashtable]$HEADERS, [string]$LOG_FILE)
    $MAX_ATTEMPTS = 64
    $attempts = 2
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    while($attempts -le $MAX_ATTEMPTS){
        for($i = 0; $i -lt $attempts; $i++){
           $response = RemoveDocFromQueue $URI $HEADERS $LOG_FILE
           If ($response){
            return $response
            }
        }
        $attempts = [Math]::Pow($attempts,2)
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
       try{
        $response = Invoke-WebRequest -Uri $URI -Method DELETE -Headers $HEADERS
        return $response 
        }
        catch {
            WriteToLog $_.Exception.Message $LOG_FILE
            return $null
        }
}
