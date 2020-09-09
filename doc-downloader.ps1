# Eleos Document Downloader Script
# This script fetches queued documents from the Eleos API and downloads them into a folder on local machine

# Import functions from functions File
$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\doc-downloader.functions.ps1

#----------------------------------------------------------------------------------------------------------
# Constants
#----------------------------------------------------------------------------------------------------------

$DRIVE_AXLE = $false # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "***REMOVED***"

$DESTINATION_PATH = "C:\Eleos\" # Desired destination folder for the downloaded files
$LOG_DIR = "C:\Eleos\Logs\"

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) 
                         Accept = 'application/json'}

$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY)
                    Accept = 'application/json'}

$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }

$BASE_URI = "https://squid-fortress-staging.eleostech.com"
#----------------------------------------------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------------------------------------------

# Functions are defined in doc-downloader.functions.ps1

#----------------------------------------------------------------------------------------------------------
# Main Script
#----------------------------------------------------------------------------------------------------------

# Checks and Creates Directory if it does not exist
CheckDirectory $DESTINATION_PATH
CheckDirectory $LOG_DIR 

# Creates LOG File
Set-Variable LOG_FILE (CreateLogFile $LOG_DIR) -Option ReadOnly -Force

# Creates Timestamp for LOG file
$Timestamp = Get-Date -format "dd-MMM-yyyy HH:mm:s"
WriteToLog ("`r`nScript Executed at: " + $Timestamp + "`r`n") $LOG_FILE

# Starts Timer for LOG file
$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$file_count = 0
do 
{
    WriteToLog ("Calling " + $URI + "`r`n") $LOG_FILE
    $URI = $BASE_URI + "/api/v1/documents/queued/next"
    try{ 
        WriteToLog "Getting Next Document in Queue..." $LOG_FILE
        $response = GetNextDoc $URI $HEADERS $LOG_FILE
        If ($response.StatusCode -eq 302)
        {
            $file_count++
            WriteToLog "Found Document in Queue..." $LOG_FILE
            $redirect = $BASE_URI + $response.Headers["Location"]
            $queuedDoc = GetDocFromQueue $redirect $HEADERS $LOG_FILE
            $filename = CreateDownloadFile $file_count
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $downloadURI = $queuedDoc.download_url
            WriteToLog ("Downloading Document from " + $downloadURI) $LOG_FILE
            try{
                wget $filename -OutFile $DESTINATION_PATH/$filename
            }
            catch {
                WriteToLog $_.Exception.Message $LOG_FILE
                break
            }
            
            $removeDoc = RemoveDocFromQueue $redirect $HEADERS $LOG_FILE
            If ($removeDoc)
            {
                WriteToLog ("Document Removed from Queue with Status Code: " + $removeDoc.StatusCode + "`r`n") $LOG_FILE
            }
            Else 
            {
                WriteToLog ("Error Removing Document from the Queue after several attempts`r`n") $LOG_FILE
            }
        }
        Else
        {
            WriteToLog ("No Documents in Queue: Response returned " + $response.StatusCode + "`r`n") $LOG_FILE
        }
    }
    catch [System.Net.WebException]
    {
        WriteToLog ("An exception has occured: " + $_.Exception.Message + "`r`n") $LOG_FILE
    }
}
while($response.StatusCode -eq 302)

# Ends Timer for LOG file
$Timer.Stop()
WriteToLog ("Script total run time: " + $Timer.Elapsed.ToString()) $LOG_FILE