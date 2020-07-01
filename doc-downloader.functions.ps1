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
    $CurrentTime = Get-Date -Format yyyy-MM-ddTHH
    $filename = ("Eleos-" + ($CurrentTime + ".log"))

    return $filename;
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

#----------------------------------------------------------------------------------------------------------
# Eleos API Consumer Functions
#----------------------------------------------------------------------------------------------------------

function GetNextDoc
{ param([string]$URI, [hashtable]$HEADERS, [string]$file)

    $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    return $response
}

function GetDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS)

    $response = Invoke-WebRequest -Uri $URI -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    return $response
}

function RemoveDocFromQueue
{ param([string]$URI, [hashtable]$HEADERS)

    $response = Invoke-WebRequest -Uri $URI -Method DELETE -Headers $HEADERS
    
    return $response
}
