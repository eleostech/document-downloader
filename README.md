# Eleos download script

## Background

Our larger customers generally have an enterprise-grade document management system that have more features than the Drive Axle Hub, so they prefer to download every document scanned through the Eleos Platform and pull it into that system instead.

Today, they do this by running a small Windows .BAT file that we provide, which connects to our fake FTP server and downloads all of the available files. These files are named either numerically (`12345.zip`) or with a special "filename template," which sticks information about the document (who scanned it, document types, identifying numbers, etc.) into the filename. These tend to look like `12345_FRD_JOREG.zip`, or worse.

We are introducing a REST API (documented here: <https://test-dev.eleostech.com/platform/platform.html#tag/Documents>) that lets people do the same thing, but over a secure connection, and without using an ancient protocol.

We need a replacement for the .BAT file that can be run/scheduled by the customer on a computer of their choosing, which will fetch any queued documents from our API and download them to the local filesystem, to a given folder.

An example is worth a lot of words. Here's the package (.BAT script plus some documentation) we provide today: <https://s3.amazonaws.com/drive-axle-integration/DriveAxleClientScript.zip>

(This relies on an email/password authentication scheme, which is going away in favor of the API key.)

## Facts that constrain the solution

1. Most of the document management systems support monitoring a folder and automatically ingesting any document(s) that appear in that folder. Therefore, downloading the documents into a given folder is sufficient.
2. Almost everyone (or maybe even everyone) imports their documents using a Windows box.
3. Everyone seems to set up these scripts to run on a schedule, like every 5 minutes or so.
4. Once in a while, something goes wrong with the downloader, and it's helpful for the customer to be able to review/provide a log file containing the last few days of activity (which files were downloaded, timestamps of when the script ran and checked for new documents, any errors encountered, etc.)
5. A lot of folks have little custom tweaks they make to the script: a common modification is to put different document types in different folders.
6. Many people run comically old versions of Windows Server. Windows Server 2012 is probably the oldest common one.

Given everything above, PowerShell 4.0 (https://docs.microsoft.com/en-us/previous-versions/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-4.0) seems like the right tool. It's well-supported across a variety of Windows versions, it lets people who need to tweak the script do so easily without a compilation environment, and it has built-in support for HTTP calls

## Let's build it

Other than that, build the script _you'd_ want if you needed something that worked reliably, failed obviously, and was easy to understand and modify at 10pm on a Friday when a co-worker calls you, panicked, because they are not getting new documents from "The Eleos."


## Test Suite

The Tests folder contains a set of unit tests for each method in the doc-downloader.functions.ps1. To run this test suite you must have Pester installed. The unit make calls to an ASP.net core API "Mock Server" found in the MockServer directory so this must also be installed for the test suite to pass. 

### Steps to run:
1. Start the "Mock Server" API in IIS Express. 
2. Run test suite in powershell.
3. Stop "Mock Server" API. 

### Dependencies:
- Pester
- .Net Framework
- IIS Express 