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

Describe 'Get-OperatingSystem' {
    It 'recognizes Windows 11 as a supported client OS' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Get-OperatingSystem\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Get-OperatingSystem from ConfigMgrClientHealth.ps1'
        }

        Invoke-Expression $functionMatch.Value

        Mock Get-CimInstance {
            [pscustomobject]@{
                Caption = 'Microsoft Windows 11 Pro'
                OSArchitecture = '64-bit'
            }
        }

        $result = Get-OperatingSystem

        $result | Should -Be 'Windows 11 64-Bit'
    }
}

Describe 'Repair-WMI' {
    It 'checks and restores the WMI service state during repair' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Repair-WMI\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Repair-WMI from ConfigMgrClientHealth.ps1'
        }

        Invoke-Expression $functionMatch.Value

        $script:WmiStopCalls = 0
        $script:WmiStartCalls = 0
        $script:CcmState = 'Running'
        $script:WmiState = 'Running'

        Mock Get-Service {
            if ($Name -eq 'ccmexec') {
                return [pscustomobject]@{ Name = $Name; Status = $script:CcmState }
            }
            return [pscustomobject]@{ Name = $Name; Status = $script:WmiState }
        } -ParameterFilter { $Name -in @('ccmexec', 'winmgmt') }

        Mock Stop-Service {
            $script:WmiStopCalls++
            if ($Name -eq 'ccmexec') {
                $script:CcmState = 'Stopped'
            }
            else {
                $script:WmiState = 'Stopped'
            }
        }
        Mock Start-Service {
            $script:WmiStartCalls++
            $script:WmiState = 'Running'
        }
        Mock Test-Path { $false }

        Repair-WMI

        $script:WmiStopCalls | Should -Be 2
        $script:WmiStartCalls | Should -Be 1
    }
}

Describe 'Repair-WMI logging' {
    It 'logs the service state and Windows build during repair' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw

        $osPattern = '(?ms)^\s*Function\s+Get-OperatingSystem\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $osMatch = [regex]::Match($sourceContent, $osPattern)
        if (-not $osMatch.Success) {
            throw 'Unable to extract Get-OperatingSystem from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $osMatch.Value

        $buildLabelPattern = '(?ms)^\s*Function\s+Get-WindowsBuildFamilyLabel\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $buildLabelMatch = [regex]::Match($sourceContent, $buildLabelPattern)
        if (-not $buildLabelMatch.Success) {
            throw 'Unable to extract Get-WindowsBuildFamilyLabel from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $buildLabelMatch.Value

        $pattern = '(?ms)^\s*Function\s+Repair-WMI\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Repair-WMI from ConfigMgrClientHealth.ps1'
        }

        Invoke-Expression $functionMatch.Value

        $script:WarningMessages = @()
        Mock Get-OperatingSystem { 'Windows 11 64-Bit' }
        Mock Get-CimInstance {
            [pscustomobject]@{
                Caption = 'Microsoft Windows 11 Pro'
                BuildNumber = '26100'
                Version = '10.0.26100'
            }
        }
        Mock Get-Service {
            if ($Name -eq 'ccmexec') {
                return [pscustomobject]@{ Name = $Name; Status = 'Running' }
            }
            return [pscustomobject]@{ Name = $Name; Status = 'Running' }
        } -ParameterFilter { $Name -in @('ccmexec', 'winmgmt') }
        Mock Write-Warning { $script:WarningMessages += $Message }
        Mock Stop-Service {}
        Mock Start-Service {}
        Mock Test-Path { $false }

        Repair-WMI

        ($script:WarningMessages -join ' ') | Should -Match 'Windows 11|26100|26H2|ccmexec=Running|winmgmt=Running'
    }
}

Describe 'Get-OperatingSystemDisplayName' {
    It 'includes the normalized build-family label in the detected OS name' {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw

        $osPattern = '(?ms)^\s*Function\s+Get-OperatingSystem\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $osMatch = [regex]::Match($sourceContent, $osPattern)
        if (-not $osMatch.Success) {
            throw 'Unable to extract Get-OperatingSystem from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $osMatch.Value

        $labelPattern = '(?ms)^\s*Function\s+Get-OperatingSystemDisplayName\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $labelMatch = [regex]::Match($sourceContent, $labelPattern)
        if (-not $labelMatch.Success) {
            throw 'Unable to extract Get-OperatingSystemDisplayName from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $labelMatch.Value

        $buildPattern = '(?ms)^\s*Function\s+Get-WindowsBuildFamilyLabel\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $buildMatch = [regex]::Match($sourceContent, $buildPattern)
        if (-not $buildMatch.Success) {
            throw 'Unable to extract Get-WindowsBuildFamilyLabel from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $buildMatch.Value

        Mock Get-OperatingSystem { 'Windows 11 64-Bit' }
        Mock Get-CimInstance {
            [pscustomobject]@{ BuildNumber = '26100' }
        }

        $result = Get-OperatingSystemDisplayName

        $result | Should -Be 'Windows 11 64-Bit 26H2'
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
