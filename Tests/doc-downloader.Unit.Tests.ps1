Describe "doc-downloader.functions Unit Tests" {
    BeforeAll {
        # Construct the path to the functions file using $PSScriptRoot
        $rootDir = Split-Path -Parent $PSScriptRoot
        $functionsPath = Join-Path $rootDir "doc-downloader.functions.ps1"

        Write-Host "Importing functions from: $functionsPath"

        # Check if the file exists before dot-sourcing
        if (Test-Path $functionsPath) {
            . $functionsPath
        } else {
            Write-Error "Could not find functions file at $functionsPath"
            exit 1
        }
    }
    
    Context "Helper Functions" {
        It "CreateLogFile returns a path with the current date" {
            Set-StrictMode -Version 2.0
            Mock Get-Date { return "2023-10-27" }
            
            $testLogDir = "Logs"
            $result = CreateLogFile $testLogDir
            $expected = Join-Path $testLogDir "Eleos-2023-10-27.log"
            $result | Should -Be $expected
        }

        It "CheckDirectory creates a directory if it doesn't exist" {
            Mock Test-Path { return $false }
            Mock New-Item { return $true } # Success
            
            CheckDirectory "C:\NewFolder"
            
            Assert-MockCalled New-Item -Times 1 -Exactly -ParameterFilter { 
                $Path -eq "C:\NewFolder" -and $ItemType -eq "directory" 
            }
        }

        It "CheckDirectory does NOT create a directory if it exists" {
            Mock Test-Path { return $true }
            Mock New-Item
            
            CheckDirectory "C:\ExistingFolder"
            
            Assert-MockCalled New-Item -Times 0
        }

        It "CreateDownloadFile produces filename with correct extension" {
            # The function expects 'filename' in the string to parse it properly
            $URI = "http://example.com/download?id=123&filename=test.zip"
            $result = CreateDownloadFile $URI 1
            $result | Should -BeLike "Eleos-*.zip"
        }

    }

    Context "API Consumption with Mocking" {
        BeforeEach {
            # Reset mocks before each test
            Mock Invoke-WebRequest { 
                # Default mock behavior
                return [PSCustomObject]@{ StatusCode = 200; Content = '{"status":"ok"}' }
            }
            Mock WriteToLog {} # Don't actually write logs
        }

        It "MakeHttpGetCall handles 302 Redirect (Success Path)" {
            $MockResponse = [PSCustomObject]@{ 
                StatusCode = 302; 
                Headers = @{ Location = "/redirected" } 
            }
            
            # Use -ParameterFilter to control mock behavior based on input
            Mock Invoke-WebRequest { return $MockResponse }
            
            $result = MakeHttpGetCall "http://example.com" @{} "log.txt"
            
            $result.StatusCode | Should -Be 302
            $result.Headers.Location | Should -Be "/redirected"
        }

        It "MakeHttpGetCall throws WebException on 404" {
            # In PowerShell 5, Invoke-WebRequest throws a WebException for 404s by default.
            # Our function catches exceptions and re-throws a [System.Net.WebException].
            # We must mock Invoke-WebRequest to THROW so the function's 'catch' block is triggered.
            Mock Invoke-WebRequest { 
                throw [System.Net.WebException]::new("404 Not Found")
            }
            
            { MakeHttpGetCall "http://example.com" @{} "log.txt" } | Should -Throw -ExceptionType ([System.Net.WebException])
        }

        It "ExponentialDeleteRetry retries on failure and eventually gives up" {
            Mock MakeHttpDeleteCall { return $null }
            Mock Start-Sleep {} # Don't actually wait
            
            $result = ExponentialDeleteRetry "http://example.com" @{} "log.txt"
            
            $result | Should -Be $null
            Assert-MockCalled MakeHttpDeleteCall -Times 4 # MAX_ATTEMPTS is 5, loop starts at 1
        }

        It "MakeHttpGetCall handles 304 Not Modified" {
            $MockResponse = [PSCustomObject]@{ StatusCode = 304 }
            Mock Invoke-WebRequest { return $MockResponse }
            
            $result = MakeHttpGetCall "http://example.com" @{} "log.txt"
            $result.StatusCode | Should -Be 304
        }

        It "MakeHttpGetCall throws WebException on 500 Internal Server Error" {
            Mock Invoke-WebRequest { 
                throw [System.Net.WebException]::new("500 Internal Server Error")
            }
            
            { MakeHttpGetCall "http://example.com" @{} "log.txt" } | Should -Throw -ExceptionType ([System.Net.WebException])
        }

        It "RemoveDocFromQueue returns 200 on success" {
            $MockResponse = [PSCustomObject]@{ StatusCode = 200 }
            Mock MakeHttpDeleteCall { return $MockResponse }
            
            $result = RemoveDocFromQueue "http://example.com/doc/1" @{} "log.txt"
            $result.StatusCode | Should -Be 200
        }

        It "RemoveDocFromQueue retries and eventually returns null on persistent failure" {
            Mock MakeHttpDeleteCall { return $null }
            Mock Start-Sleep {}
            
            $result = RemoveDocFromQueue "http://example.com/doc/1" @{} "log.txt"
            $result | Should -Be $null
            # Initial call + 4 retries in ExponentialDeleteRetry = 5 total
            Assert-MockCalled MakeHttpDeleteCall -Times 5 -Exactly
        }
    }
}
