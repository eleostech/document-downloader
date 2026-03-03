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
        $global:HEADERS = @{ 
            Authorization = "Key key=$API_KEY"
            Accept = 'application/json'
        }
        $global:LOG_FILE = "integration-test.log"
        if (Test-Path $LOG_FILE) { Remove-Item $LOG_FILE }
    }

    Context "API Integration with Mock Server" {
        It "GetNextDoc should handle a 302 redirect from the mock server" -Skip:($PSVersionTable.PSVersion.Major -eq 6) {
            $uri = "$global:BASE_URL/api/v1/documents/queued/next"
            $response = GetNextDoc $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 302
            $response.Headers.Location | Should -Not -BeNullOrEmpty
        }

        It "GetDocFromQueue should fetch valid metadata from the mock server" {
            $uri = "$global:BASE_URL/api/v1/documents/queued/1"
            $response = GetDocFromQueue $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 200
            
            Write-Host "DEBUG: Response Content: $($response.Content)"
            
            $data = $response.Content | ConvertFrom-Json
            $data.document_identifier | Should -Be "101298333"
            $data.download_url | Should -Not -BeNullOrEmpty
        }

        It "RemoveDocFromQueue should successfully delete a document" {
            $uri = "$global:BASE_URL/api/v1/documents/queued/1"
            $response = RemoveDocFromQueue $uri $global:HEADERS $global:LOG_FILE
            
            $response.StatusCode | Should -Be 200
            $data = $response.Content | ConvertFrom-Json
            $data.message | Should -Be "Document deleted successfully."
        }

        It "GetFilename should correctly extract filename from mock server headers" {
            $uri = "$global:BASE_URL/api/download/validHeader"
            $filename = GetFilename $uri 1 $global:LOG_FILE
            
            $filename | Should -Be "filename.jpg"
        }
    }
}
