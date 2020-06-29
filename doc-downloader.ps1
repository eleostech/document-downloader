
# Eleos Document Downloader Script
# This script fetches queued documents from the Eleos API and downloads them into a folder on local machine

#----------------------------------------------------------------------------------------------------------

$DRIVE_AXLE = $false; # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "Eepv+BdqqMjFKIY7CUsL93dp4ILhhyrurjiQLuysjfu6D2PhhA==";

$DESTINATION_PATH = "C:\Eleos\"; # Desired destination folder for the downloaded files

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) }
$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY) }
$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }

$BASE_URI = "https://squid-fortress-staging.eleostech.com";

#----------------------------------------------------------------------------------------------------------

function CreateTimestamp
{
    $Timestamp = Get-Date -format "dd-MMM-yyyy HH:mm"
    return $Timestamp;
}

function CreateLogFile 
{
    $CurrentTime = Get-Date -Format yyyy-MM-ddTHH
    return $CurrentTime;
}

function WriteToLog
{ param([string]$TextToWrite)
    
    $TextToWrite | Out-File $LOG_FILE -Append;
}

function GetDocument
{

    $GetNext = $BASE_URI + "/api/v1/documents/queued/next";
    WriteToLog "Calling $GetNext"
    
    $response = iwr -Uri $GetNext -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    return $response;
}

#----------------------------------------------------------------------------------------------------------

Set-Variable CREATE_LOG (CreateLogFile) -Option ReadOnly -Force;
Set-Variable LOG_FILE ("Eleos-" + ($CREATE_LOG + ".log")) -Option ReadOnly -Force;

if(-not (Test-Path $DESTINATION_PATH))
{
    new-item $DESTINATION_PATH -itemtype directory
}

$CurrentTime = CreateTimestamp;
$StartTime = ("`r`nScript Exectuted at: " + $CurrentTime + "`r`n")
WriteToLog $StartTime;

$Timer = [System.Diagnostics.Stopwatch]::StartNew();

do {
    $response = GetDocument

    If ($response.StatusCode -eq 302)
    {
        WriteToLog "Found Document in Queue..."
        $REDIRECT = $BASE_URI + $response.Headers["Location"];
        $r = iwr -Uri $REDIRECT -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
        $DOWNLOAD_URI = $r.Headers["Location"];
        WriteToLog ("Downloading Document from " + $DOWNLOAD_URI)
        $filename = $(((Get-Date).ToUniversalTime()).ToString("yyyyMMdd_HHmmss")) + ".zip"
        wget $DOWNLOAD_URI -OutFile $DESTINATION_PATH/$filename
        $removeDoc = iwr -Uri $REDIRECT -Method DELETE -Headers $HEADERS
        If ($removeDoc.StatusCode -eq 200)
        {
            WriteToLog ("Document Removed from Queue with Status Code: " + $removeDoc.StatusCode + "`r`n")
        }
        Else {
            WriteToLog ("Error Removing Document: Response returned " + $removeDoc.StatusCode + "`r`n")
        }
    }
    Else
    {
        WriteToLog ("No Documents in Queue: Response returned " + $response.StatusCode + "`r`n");
    }
}
while($response.StatusCode -eq 302)

$Timer.Stop();
$RunTime = ("Script total run time: " + $Timer.Elapsed.ToString())
WriteToLog $RunTime;