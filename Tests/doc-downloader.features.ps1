$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1
$proj = Split-Path -Path $src -Parent


Describe 'Some Tests' {
    Mock 'Invoke-WebRequest' {
      $json = Get-Content ($proj +"\document-downloader\MockServer\MockServer\Payloads\payload.json")
      return $json | ConvertFrom-Json 
    }

    Mock 'GetDocFromQueue' {
        $json = Get-Content ($proj +"\document-downloader\MockServer\MockServer\Payloads\payload.json")
        return $json | ConvertFrom-Json 
    }

    $test = GetDocFromQueue "Bogus" @{"fake" = "fake"} "bogus file"
    $test.download_url

    it 'should invoke Get-FakeFunction'{
        Assert-MockCalled GetDocFromQueue -Times 1              
    }
}

Describe "DescribeName" {

    Mock 'GetNextDoc'{
        $response = @{'StatusCode' = 304}
        return $response
    }
    $ran = $false

    $response = GetNextDoc "Bogus" @{"fake" = "fake"} "bogus file"
    while($response.StatusCode -eq 302){
        $ran = $true
        $response = GetNextDoc "Bogus" @{"fake" = "fake"} "bogus file"
    }

    it 'GetNextDoc should not run loop if status code is 304'{
        $ran | Should be $false
        Assert-MockCalled GetNextDoc -Times 1
    }
}