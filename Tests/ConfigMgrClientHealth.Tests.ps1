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

        $helperPattern = '(?ms)^\s*Function\s+Get-CimOrWmiInstance\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $helperMatch = [regex]::Match($sourceContent, $helperPattern)
        if (-not $helperMatch.Success) {
            throw 'Unable to extract Get-CimOrWmiInstance from ConfigMgrClientHealth.ps1'
        }
        Invoke-Expression $helperMatch.Value

        $PowerShellVersion = 7
        $operatingSystem = [pscustomobject]@{
            Caption = 'Microsoft Windows 11 Pro'
            OSArchitecture = '64-bit'
        }

        Mock Get-CimInstance { $operatingSystem }
        Mock Get-WmiObject { $operatingSystem }

        $result = Get-OperatingSystem

        Should -Invoke Get-CimInstance -Times 1 -Exactly

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

Describe 'Update-SQL' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Update-SQL\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Update-SQL from ConfigMgrClientHealth.ps1'
        }

        $script:UpdateSqlSource = $functionMatch.Value

        function Test-ValuesBeforeLogUpdate {}
        function Get-XMLConfigSQLServer {}
        function Get-SmallDateTime {}
        function Out-LogFile { param($Xml, $Text, $Severity) }
        function Invoke-Sqlcmd2 { param($ServerInstance, $Database, $Query, $SqlParameters) }

        function New-TestLog {
            $log = [ordered]@{}
            foreach ($name in @('Hostname', 'Operatingsystem', 'Architecture', 'Build', 'Manufacturer', 'Model', 'InstallDate', 'OSUpdates', 'LastLoggedOnUser', 'ClientVersion', 'PSVersion', 'PSBuild', 'Sitecode', 'Domain', 'MaxLogSize', 'MaxLogHistory', 'CacheSize', 'ClientCertificate', 'ProvisioningMode', 'DNS', 'Drivers', 'Updates', 'PendingReboot', 'LastBootTime', 'OSDiskFreeSpace', 'Services', 'AdminShare', 'StateMessages', 'WUAHandler', 'WMI', 'RefreshComplianceState', 'HWInventory', 'Version', 'ClientInstalled', 'SWMetering', 'BITS', 'PatchLevel', 'ClientInstalledReason')) {
                $log[$name] = 'OK'
            }
            $log.Hostname = 'PC01'
            $log.OSUpdates = $null
            $log.ClientInstalled = $null
            [pscustomobject]$log
        }
    }

    BeforeEach {
        Invoke-Expression $script:UpdateSqlSource

        $script:Xml = $null
        $Version = '0.9.0'
        $script:SqlCall = $null
        Mock Test-ValuesBeforeLogUpdate {}
        Mock Get-XMLConfigSQLServer { 'sqlserver01' }
        Mock Get-SmallDateTime { '2026-01-01 00:00:00' }
        Mock Out-LogFile {}
        Mock Invoke-Sqlcmd2 { $script:SqlCall = @{ Query = $Query; SqlParameters = $SqlParameters } }
    }

    It 'passes values containing quotes as parameters instead of query text' {
        $log = New-TestLog
        $log.LastLoggedOnUser = "DOMAIN\o'brien"
        $log.Model = "Model'); DROP TABLE dbo.Clients; --"

        Update-SQL -Log $log

        $script:SqlCall.Query | Should -Not -Match "o'brien"
        $script:SqlCall.Query | Should -Not -Match 'DROP TABLE'
        $script:SqlCall.Query | Should -Match 'LastLoggedOnUser=@LastLoggedOnUser'
        $script:SqlCall.Query | Should -Match 'WHERE Hostname = @Hostname'
        $script:SqlCall.SqlParameters['LastLoggedOnUser'] | Should -Be "DOMAIN\o'brien"
        $script:SqlCall.SqlParameters['Model'] | Should -Be "Model'); DROP TABLE dbo.Clients; --"
        $script:SqlCall.SqlParameters['Hostname'] | Should -Be 'PC01'
    }

    It 'omits OSUpdates and ClientInstalled when they are null' {
        $log = New-TestLog

        Update-SQL -Log $log

        $script:SqlCall.Query | Should -Not -Match 'OSUpdates'
        $script:SqlCall.Query | Should -Not -Match 'ClientInstalled[^R]'
        $script:SqlCall.SqlParameters.Contains('OSUpdates') | Should -BeFalse
        $script:SqlCall.SqlParameters.Contains('ClientInstalled') | Should -BeFalse
    }

    It 'includes OSUpdates and ClientInstalled when they have values' {
        $log = New-TestLog
        $log.OSUpdates = '2026-01-01 00:00:00'
        $log.ClientInstalled = '2026-01-02 00:00:00'

        Update-SQL -Log $log

        $script:SqlCall.Query | Should -Match 'OSUpdates=@OSUpdates'
        $script:SqlCall.Query | Should -Match 'ClientInstalled=@ClientInstalled'
        $script:SqlCall.SqlParameters['OSUpdates'] | Should -Be '2026-01-01 00:00:00'
        $script:SqlCall.SqlParameters['ClientInstalled'] | Should -Be '2026-01-02 00:00:00'
    }

    It 'sends null values as empty strings like the previous query did' {
        $log = New-TestLog
        $log.Manufacturer = $null

        Update-SQL -Log $log

        $script:SqlCall.SqlParameters['Manufacturer'] | Should -Be ''
    }

    It 'uses the same parameter for Version in the update and insert statements' {
        $log = New-TestLog
        $log.Version = 'stale'

        Update-SQL -Log $log

        $script:SqlCall.Query | Should -Match 'Version=@Version'
        $script:SqlCall.Query | Should -Match 'VALUES \(.*@Version'
        $script:SqlCall.SqlParameters['Version'] | Should -Be '0.9.0'
    }

    It 'does not write parameter values to the log when the SQL call fails' {
        $log = New-TestLog
        $log.LastLoggedOnUser = 'DOMAIN\user01'
        Mock Invoke-Sqlcmd2 { throw [System.Exception]::new('Connection failed') }

        { Update-SQL -Log $log -ErrorAction SilentlyContinue } | Should -Not -Throw

        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter {
            $Text -match 'Connection failed' -and $Text -notmatch 'user01'
        }
    }
}

Describe 'Get-CimOrWmiInstance' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Get-CimOrWmiInstance\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Get-CimOrWmiInstance from ConfigMgrClientHealth.ps1'
        }

        $script:HelperSource = $functionMatch.Value
    }

    BeforeEach {
        Invoke-Expression $script:HelperSource

        Mock Get-CimInstance { 'cim' }
        Mock Get-WmiObject { 'wmi' }
    }

    It 'uses Get-CimInstance with every supplied parameter on PowerShell 6 or later' {
        $PowerShellVersion = 7

        $result = Get-CimOrWmiInstance Win32_Service -Namespace 'root\cimv2' -Filter "Name='winmgmt'" -Property StartMode, Status

        $result | Should -Be 'cim'
        Should -Invoke Get-WmiObject -Times 0 -Exactly
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $ClassName -eq 'Win32_Service' -and $Namespace -eq 'root\cimv2' -and $Filter -eq "Name='winmgmt'" -and ($Property -join ',') -eq 'StartMode,Status'
        }
    }

    It 'uses Get-WmiObject with every supplied parameter on Windows PowerShell' {
        $PowerShellVersion = 5

        $result = Get-CimOrWmiInstance Win32_Service -Namespace 'root\cimv2' -Filter "Name='winmgmt'" -Property StartMode, Status

        $result | Should -Be 'wmi'
        Should -Invoke Get-CimInstance -Times 0 -Exactly
        Should -Invoke Get-WmiObject -Times 1 -Exactly -ParameterFilter {
            $Class -eq 'Win32_Service' -and $Namespace -eq 'root\cimv2' -and $Filter -eq "Name='winmgmt'" -and ($Property -join ',') -eq 'StartMode,Status'
        }
    }

    It 'does not pass optional parameters that were not supplied' {
        $PowerShellVersion = 7

        Get-CimOrWmiInstance Win32_OperatingSystem | Out-Null

        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            -not ($PSBoundParameters.ContainsKey('Namespace') -or $PSBoundParameters.ContainsKey('Filter') -or $PSBoundParameters.ContainsKey('Property'))
        }
    }

    It 'turns query errors into terminating errors when called with -ErrorAction Stop' {
        $PowerShellVersion = 7
        Mock Get-CimInstance { Write-Error 'Invalid namespace' }

        { Get-CimOrWmiInstance SMS_Client -Namespace 'root\ccm' -ErrorAction Stop } | Should -Throw '*Invalid namespace*'
        { Get-CimOrWmiInstance SMS_Client -Namespace 'root\ccm' -ErrorAction SilentlyContinue } | Should -Not -Throw
    }
}
