Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:SourceFile = Join-Path $script:RepoRoot 'ConfigMgrClientHealth.ps1'

    $script:SourceContent = Get-Content -Path $script:SourceFile -Raw

    $script:FunctionNames = @(
        'Get-XMLConfigClientShare',
        'Get-XMLConfigUpdatesShare'
    )

    foreach ($functionName in $script:FunctionNames) {
        $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($functionName))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
        $match = [regex]::Match($script:SourceContent, $pattern)

        if (-not $match.Success) {
            throw "Unable to extract $functionName from $script:SourceFile"
        }

        Invoke-Expression $match.Value
    }
}

Describe 'Get-XMLConfigClientShare' {
    It 'returns the configured share when XML contains a client share' {
        $script:config = $true
        $script:Xml = [xml] @'
<Configuration>
  <Client Name="Share">\\server01\ClientHealth$</Client>
</Configuration>
'@

        $result = Get-XMLConfigClientShare

        $result | Should -Be '\\server01\ClientHealth$'
    }

    It 'defaults to the script location when the configured client share is empty' {
        $script:config = $true
        $script:Xml = [xml] @'
<Configuration>
  <Client Name="Share"></Client>
</Configuration>
'@
        $global:ScriptPath = 'C:\Temp\ClientHealth'

        $result = Get-XMLConfigClientShare

        $result | Should -Be 'C:\Temp\ClientHealth'
    }
}

Describe 'Get-XMLConfigUpdatesShare' {
    It 'returns the configured updates share when present' {
        $script:config = $true
        $script:Xml = [xml] @'
<Configuration>
  <Option Name="Updates" Share="\\server01\ClientHealth$\Updates" Enable="True" />
</Configuration>
'@

        $result = Get-XMLConfigUpdatesShare

        $result | Should -Be '\\server01\ClientHealth$\Updates'
    }

    It 'defaults to a local Updates folder when no update share is configured' {
        $script:config = $true
        $script:Xml = [xml] @'
<Configuration>
  <Option Name="Other" Enable="True" />
</Configuration>
'@
        $global:ScriptPath = 'C:\Temp\ClientHealth'

        $result = Get-XMLConfigUpdatesShare

        $result | Should -Be 'C:\Temp\ClientHealth\Updates'
    }
}

Describe 'webservice failure handling' {
    It 'continues in degraded mode when configuration retrieval fails' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Get-ConfigFromWebservice\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Get-ConfigFromWebservice from ConfigMgrClientHealth.ps1'
        }

        Invoke-Expression $functionMatch.Value

        Mock Invoke-RestMethod {
            throw [System.Exception]::new('Web service failed')
        }

        $result = Get-ConfigFromWebservice -URI 'https://example.test/config'

        $result | Should -Be $null
    }

    It 'logs the actual exception message when the webservice call fails' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Get-ConfigFromWebservice\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Get-ConfigFromWebservice from ConfigMgrClientHealth.ps1'
        }

        Invoke-Expression $functionMatch.Value

        Mock Invoke-RestMethod {
            throw [System.Exception]::new('Web service failed')
        }

        $output = & {
            Get-ConfigFromWebservice -URI 'https://example.test/config' *>&1
        } 2>&1 | Out-String

        $output | Should -Match 'Web service failed'
    }
}
