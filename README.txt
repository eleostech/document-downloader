Installation Instructions
=========================

1. Unzip the package to a directory that is read/write accessible by
your task scheduler account.

NOTE: The system user executing the scheduled task MUST have
full read/write access to this directory.

2. Modify configurations.json, replacing [your API key] with
your Platform or Drive Axle API key. You can obtain your API key using
the instructions here:
<https://dev.eleostech.com/platform/platform.html#section/Authentication>

3. If you are a Drive Axle customer, modify `drive_axle_customer` in
configurations.json to `true`.

4. If you need, you can configure several other options, such as the
destination directory for downloaded files, by editing the relevant
constants in doc-downloader.ps1. See "Configuration Parameters" for
details.

5. Create a scheduled task to execute doc-downloader.ps1 on a periodic basis.

Additional Information
======================

Drive Axle documents will be downloaded straight to the directory speci-
fied in doc-downloader.ps1 in the form of ZIP files containing one or many individ-
ual image files. The file names of the ZIP files are guaranteed to be unique but
not necessarily sequential or ordinal. The file names take
the form of [PAGE NUMBER].[extension] where [PAGE NUMBER] is an integer
greater than one representing the page number of the image within the doc-
ument. You'll also receive a file containing metadata about the document;
see the documentation here for details:
<https://dev.eleostech.com/platform/platform.html#tag/Documents>

Alternatively, if you would prefer to receive PDF files instead of TIFF
images, your account can be configured to make PDFs available through
the Drive Axle FTP gateway. However, PDF files do not contain metadata.
The doc-downloader.ps1 script can generally be run as often as needed, but
only one instance of the script should be run at a time.

Log files of the FTP sessions will be available at C:\Eleos\Logs by default,
but this can be configured. See below for info.

Configuration Parameters
========================

Parameters listed here can be found at the top of **doc-downloader.ps1**:

    $DATED_FOLDERS: If set to $true, documents will be separated into folders
                    based on date. If set to $false, they will put into one folder.
    $DESTINATION_PATH: The destination folder where the downloaded files will be
                       stored. By default, an Eleos folder is created in C:\.
    $LOG_DIR: Folder where log files created by the script will be stored.
              These files provide meaningful feedback for when the script is
              running successfully or if it encounters any errors. By default,
              this folder is at C:\Eleos\Logs.

