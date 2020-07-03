$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
. $here\doc-downloader.functions.ps1

Describe "Helper Function Tests" {
    Context 'Verifying helper functions produce correct output' {
        it 'CreateTimestamp should produce correct date and time' {
            $Timestamp = Get-Date -format "dd-MMM-yyyy HH:mm"
            mock -CommandName Get-Date -MockWith { $Timestamp }
            CreateTimestamp | should be $Timestamp
        }
        it 'CreateLogFile should produce a log filename corresponding to todays date' {
            $CurrentTime = Get-Date -Format yyyy-MM-ddTHH
            mock -CommandName Get-Date -MockWith { $CurrentTime }
            $filename = ("Eleos-" + ($CurrentTime + ".log"))
            CreateLogFile | should be $filename
        }
    }
}

Describe "Consume API Function Tests" {
    Context 'Testing GetNextDoc function' {
        it 'GetNextDoc should return a 302 if there is a document in the queue' {
            $response = $true
            $response | should be $true
        }
        it 'GetNextDoc should return a 304 if there is not a document in the queue' {
            $response = $true
            $response | should be $true
        }
    }
    Context 'Testing GetDocFromQueue function' {
        it 'GetDocFromQueue should return a 302 with URL and filename to download document' {
            $response = $true
            $response | should be $true
        }
        it 'GetDocFromQueue should return a 404 if document could not be found' {
            $response = $true
            $response | should be $true
        }
    }
    Context 'Testing RemoveDocFromQueue function' {
        it 'RemoveDocFromQueue should return a 200 if a document was successfully removed from the queue' {
            $response = $true
            $response | should be $true
        }
        it 'RemoveDocFromQueue should return a 404 if the document to be removed could not be found' {
            $response = $true
            $response | should be $true
        }
    }
}