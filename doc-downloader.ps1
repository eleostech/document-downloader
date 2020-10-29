# Eleos Document Downloader Script
# This script fetches queued documents from the Eleos API and downloads them into a folder on local machine

# Import functions from functions File
$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\doc-downloader.functions.ps1

#----------------------------------------------------------------------------------------------------------
# Constants
#----------------------------------------------------------------------------------------------------------

$DRIVE_AXLE = $false # If Drive Axle Hub Customer - this value should be $true, otherwise $false
$API_KEY = "HCq568VGsoFaP81iYz3PiAtWTOF4fdpwuBJCQKddw3p"

$DESTINATION_PATH = "C:\Eleos\" # Desired destination folder for the downloaded files
$LOG_DIR = "C:\Eleos\Logs\"
$date = (Get-Date -Format "MM-dd").ToString()
$FILE_DIR = $DESTINATION_PATH + $date + "\"

$DRIVE_AXLE_HEADERS = @{ Authorization = ("driveaxle=" + $API_KEY) 
                         Accept = 'application/json'}

$ELEOS_HEADERS = @{ Authorization = ("key=" + $API_KEY)
                    Accept = 'application/json'}

$HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }

$BASE_URI = "https://squid-fortress-staging.eleostech.com"
#----------------------------------------------------------------------------------------------------------
# Functions are defined in doc-downloader.functions.ps1
#----------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------
# Main Script
#----------------------------------------------------------------------------------------------------------

# Checks and Creates Directory if it does not exist
CheckDirectory $DESTINATION_PATH
CheckDirectory $LOG_DIR 
CheckDirectory $FILE_DIR

# Creates LOG File
$log_file = (CreateLogFile $LOG_DIR)
# Creates Timestamp for LOG file
$Timestamp = Get-Date -format "dd-MM-yyyy HH:mm:s"
WriteToLog ("Script Executed at: " + $Timestamp + "`r`n") $log_file

# Starts Timer for LOG file
$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$file_count = 0
do{
    $URI = $BASE_URI + "/api/v1/documents/queued/next"
    WriteToLog ("Calling " + $URI + "`r`n") $log_file
    try{ 
        WriteToLog "Getting Next Document in Queue..." $log_file
        $response = GetNextDoc $URI $HEADERS $log_file
        If ($response.StatusCode -eq 302){
            WriteToLog "Found Document in Queue..." $log_file
            $redirect = $BASE_URI + $response.Headers["Location"]
            WriteToLog ("Redirecting to URL " + $redirect) $log_file
            $queuedDoc = GetDocFromQueue $redirect $HEADERS $log_file
            $queuedDoc = $queuedDoc | ConvertFrom-Json
            $downloadURI = $queuedDoc.download_url
            WriteToLog ("Downloading Document from " + $downloadURI) $log_file
            $file_count++
            try{
                $filename = GetFilename $downloadURI $file_count $log_file
                WriteToLog ("Downloading file " + $filename + " ...." + "`r`n") $log_file
                Invoke-WebRequest $downloadURI -OutFile $FILE_DIR/$filename
                WriteToLog ("File " + $filename + "  downloaded successfully to " + $FILE_DIR) $log_file
            }
            catch{
                WriteToLog ($_.Exception.Message + "`r`n" + "Error Occured at: " + (Get-Date -format "MM-dd-yyyy HH:mm:s").ToString() + "`r`n") $log_file
                break
            }
            
            WriteToLog ("Attempting to delete document " + $redirect + " from the Queue`r`n") $log_file
            $removeDoc = RemoveDocFromQueue $redirect $HEADERS $log_file
            If ($removeDoc){
                WriteToLog ("Document Removed from Queue with Status Code: " + $removeDoc.StatusCode + "`r`n") $log_file
            }
            Else{
                WriteToLog ("Error Removing Document from the Queue after several attempts`r`n") $log_file
            }
        }
        Else{
            WriteToLog ("No Documents in Queue: Response returned " + $response.StatusCode + "`r`n") $log_file
        }
    }
    catch [System.Net.WebException]{
        WriteToLog ("An exception has occured: " + $_.Exception.Message + "`r`n") $log_file
    }
}
while($response.StatusCode -eq 302)

# Ends Timer for LOG file
$Timer.Stop()
WriteToLog ("Script total run time: " + $Timer.Elapsed.ToString()) $log_file
WriteToLog ($file_count.ToString() + " documents downloaded." + "`r`n") $log_file