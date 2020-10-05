$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Split-Path -Path $here -Parent
. $src\doc-downloader.functions.ps1
$proj = Split-Path -Path $src -Parent


Describe 'Some Tests' {
    # Mock 'Invoke-WebRequest' {
    #  $json = Get-Content ($proj +"\document-downloader\MockServer\MockServer\Payloads\payload.json")
    #  return $json | ConvertFrom-Json 
    # }

    Mock 'MakeHttpGetCall' {
        return $true
    }

    #$Result = MakeHttpGetCall "Bogus" @{"fake" = "fake"} "bogus file"
    $test = MakeHttpGetCall "Bogus" @{"fake" = "fake"} "bogus file"

    it 'test should be true'{
        Assert-MockCalled MakeHttpGetCall -Times 1 
    }
    it 'should invoke Get-FakeFunction'{
        # Assert-MockCalled Invoke-WebRequest -Times 1              
    }
    it 'should not be null'{
        $Result | Should not be $null
    }
}