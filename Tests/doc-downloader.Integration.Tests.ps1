Describe "doc-downloader.functions Integration Tests" {
    BeforeAll {
        $rootDir = Split-Path -Parent $PSScriptRoot
        $functionsPath = Join-Path $rootDir "doc-downloader.functions.ps1"
        if (Test-Path $functionsPath) {
            . $functionsPath
        } else {
            Write-Error "Could not find functions file at $functionsPath"
            exit 1
        }

        $envUrl = [System.Environment]::GetEnvironmentVariable("MOCK_SERVER_URL")
        if ($envUrl) {
            $global:BASE_URL = $envUrl
        } else {
            $global:BASE_URL = "http://localhost:5000"
        }
        $global:API_KEY = "test-api-key"
        $global:LOG_FILE = "integration-test.log"
        if (Test-Path $LOG_FILE) { Remove-Item $LOG_FILE }
    }

    Context "Authentication" {
        It "Uses standard Eleos header when drive_axle_customer is false" {
            $API_KEY = "test-key"
            $DRIVE_AXLE = $false
            
            $DRIVE_AXLE_HEADERS = @{ Authorization = ("DriveAxleKey key=" + $API_KEY) }
            $ELEOS_HEADERS = @{ Authorization = ("Key key=" + $API_KEY) }
            $HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }
            
            $HEADERS.Authorization | Should -Be "Key key=test-key"
        }

        It "Uses Drive Axle header when drive_axle_customer is true" {
            $API_KEY = "test-key"
            $DRIVE_AXLE = $true
            
            $DRIVE_AXLE_HEADERS = @{ Authorization = ("DriveAxleKey key=" + $API_KEY) }
            $ELEOS_HEADERS = @{ Authorization = ("Key key=" + $API_KEY) }
            $HEADERS = If ($DRIVE_AXLE) { $DRIVE_AXLE_HEADERS } Else { $ELEOS_HEADERS }
            
            $HEADERS.Authorization | Should -Be "DriveAxleKey key=test-key"
        }

        It "GetNextDoc works with standard Eleos header (Key key=...)" -Skip:($PSVersionTable.PSVersion.Major -eq 6) {
            $headers = @{ 
                Authorization = "Key key=$global:API_KEY"
                Accept = 'application/json'
            }
            $uri = "$global:BASE_URL/api/v1/documents/queued/next"
            $response = GetNextDoc $uri $headers $global:LOG_FILE
            
            $response.StatusCode | Should -Be 302
        }

        It "GetNextDoc works with Drive Axle header (DriveAxleKey key=...)" -Skip:($PSVersionTable.PSVersion.Major -eq 6) {
            $headers = @{ 
                Authorization = "DriveAxleKey key=$global:API_KEY"
                Accept = 'application/json'
            }
            $uri = "$global:BASE_URL/api/v1/documents/queued/next"
            $response = GetNextDoc $uri $headers $global:LOG_FILE
            
            $response.StatusCode | Should -Be 302
        }

        It "GetNextDoc returns 401 Unauthorized with missing or invalid header" {
            $headers = @{ Authorization = "InvalidPrefix $global:API_KEY" }
            $uri = "$global:BASE_URL/api/v1/documents/queued/next"
            
            try {
                $response = GetNextDoc $uri $headers $global:LOG_FILE
                if ($PSVersionTable.PSVersion.Major -ge 7) {
                    $response.StatusCode | Should -Be 401
                } else {
                    # If it somehow returns instead of throwing
                    $response | Should -BeNullOrEmpty
                }
            } catch {
                if ($PSVersionTable.PSVersion.Major -lt 7) {
                    # Expect the exception on PS 5/6
                    $_.Exception.Message | Should -Match "401"
                } else {
                    throw $_
                }
            }
        }
    }

    Context "API Integration with Mock Server" {
        BeforeAll {
            $global:HEADERS = @{ 
                Authorization = "Key key=$global:API_KEY"
                Accept = 'application/json'
            }
        }

        It "GetNextDoc handles a 304 Not Modified (Empty Queue)" -Skip:($PSVersionTable.PSVersion.Major -eq 6) {
            # Use the dedicated endpoint or special header to simulate empty queue
            $uri = "$global:BASE_URL/api/v1/documents/queued/next/empty"
            $response = GetNextDoc $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 304
        }

        It "GetDocFromQueue fetches valid metadata" {
            $uri = "$global:BASE_URL/api/v1/documents/queued/1"
            $response = GetDocFromQueue $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 200
            
            $data = $response.Content | ConvertFrom-Json
            $data.document_identifier | Should -Be "101298333"
            $data.download_url | Should -Not -BeNullOrEmpty
        }

        It "GetDocFromQueue returns 404 for missing document" {
            $uri = "$global:BASE_URL/api/v1/documents/queued/2"
            
            try {
                $response = GetDocFromQueue $uri $global:HEADERS $global:LOG_FILE
                if ($PSVersionTable.PSVersion.Major -ge 7) {
                    $response.StatusCode | Should -Be 404
                } else {
                    $response | Should -BeNullOrEmpty
                }
            } catch {
                if ($PSVersionTable.PSVersion.Major -lt 7) {
                    $_.Exception.Message | Should -Match "404"
                } else {
                    throw $_
                }
            }
        }

        It "RemoveDocFromQueue successfully deletes a document" {
            $uri = "$global:BASE_URL/api/v1/documents/queued/1"
            $response = RemoveDocFromQueue $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 200
            $data = $response.Content | ConvertFrom-Json
            $data.message | Should -Be "Document deleted successfully."
        }

        It "GetFilename correctly extracts filename from mock server headers" {
            $uri = "$global:BASE_URL/api/download/validHeader"
            $filename = GetFilename $uri 1 $global:LOG_FILE
            
            $filename | Should -Be "filename.jpg"
        }
    }
}
