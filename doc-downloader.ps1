# Eleos Document Downloader Script
# This script fetches queued documents from the Eleos API and downloads them into a folder on local machine

# Import functions from functions File
$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\doc-downloader.functions.ps1

#----------------------------------------------------------------------------------------------------------
# Constants
#----------------------------------------------------------------------------------------------------------

$DRIVE_AXLE = $false # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "Placeholder"

$DESTINATION_PATH = "C:\Eleos\" # Desired destination folder for the downloaded files

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) }
$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY) }
$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }

$BASE_URI = "https://squid-fortress-staging.eleostech.com"

#----------------------------------------------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------------------------------------------

<<<<<<< HEAD
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
    WriteToLog ("Calling $GetNext")
    $response = Invoke-WebRequest -Uri $GetNext -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
    
    return $response;
}
#This Function implements the exponential retry method in the case of a failure on delete request
function ExpWait
{param([string]$URI, [string]$HDRS, [int32]$Curr_Backfoff)
    $MAX_BACKOFF = 32
    if($Curr_Backoff -ge $MAX_BACKOFF){exit}

    $response = Invoke-WebRequest -Uri $redirect -Headers $HEADERS -MaximumRedirection 0 -ErrorAction SilentlyContinue
    If ($response.StatusCode -eq 200){return $response.StatusCode}
    Else {
        ExpWait($URI, $HDRS, $Curr_Backfoff * $Curr_Backfoff)
    }
}
=======
# Functions are defined in doc-downloader.functions.ps1

>>>>>>> corey
#----------------------------------------------------------------------------------------------------------
# Main Script
#----------------------------------------------------------------------------------------------------------

# Creates LOG File
Set-Variable LOG_FILE (CreateLogFile) -Option ReadOnly -Force

# Checks and Creates Directory if it does not exist
CheckDirectory $DESTINATION_PATH

# Creates Timestamp for LOG file
$Timestamp = CreateTimestamp
WriteToLog ("`r`nScript Executed at: " + $Timestamp + "`r`n") $LOG_FILE

# Starts Timer for LOG file
$Timer = [System.Diagnostics.Stopwatch]::StartNew()

do 
{

    $URI = $BASE_URI + "/api/v1/documents/queued/next"
    WriteToLog ("Calling " + $URI + "`r`n") $LOG_FILE
    try 
    { 
        $response = GetNextDoc $URI $HEADERS
        If ($response.StatusCode -eq 302)
        {
            WriteToLog "Found Document in Queue..." $LOG_FILE
            $redirect = $BASE_URI + $response.Headers["Location"]
            $queuedDoc = GetDocFromQueue $redirect $HEADERS
            $downloadURI = $queuedDoc.Headers["Location"]
            WriteToLog ("Downloading Document from " + $DOWNLOAD_URI) $LOG_FILE
            $filename = queuedDoc.Headers["Content-Disposition"]
            wget $downloadURI -OutFile $DESTINATION_PATH/$filename
            $removeDoc = RemoveDocFromQueue $redirect $HEADERS
            If ($removeDoc.StatusCode -eq 200)
            {
                WriteToLog ("Document Removed from Queue with Status Code: " + $removeDoc.StatusCode + "`r`n") $LOG_FILE
            }
            Else 
            {
                WriteToLog ("Error Removing Document: Response returned " + $removeDoc.StatusCode + ". Trying again... `r`n") $LOG_FILE
                $retry = ExpWait $redirect $HEADERS 1
                If($retry -eq 200){
                    WriteToLog ("Document Removed from Queue with Status Code: " + $retry + "`r`n") $LOG_FILE 
                }
                Else{
                    WriteToLog ("Error Removing Document: Response returned " + $retry + "`r`n") $LOG_FILE
                }
            }
        }
        Else
        {
            WriteToLog ("No Documents in Queue: Response returned " + $response.StatusCode + "`r`n") $LOG_FILE
        }
    }
    catch [System.Net.WebException]
    {
        WriteToLog ("An exception has occured: " + $($_.Exception.Message) + "`r`n") $LOG_FILE
    }
}
while($response.StatusCode -eq 302)

# Ends Timer for LOG file
$Timer.Stop()
WriteToLog ("Script total run time: " + $Timer.Elapsed.ToString()) $LOG_FILE