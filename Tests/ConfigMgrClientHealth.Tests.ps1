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
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }

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
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }

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

Describe 'Test-Service' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $functionNames = @(
            'Test-Service', 'ConvertTo-ServiceStartupType', 'Get-ServiceStartupType', 'Repair-ServiceStartupType',
            'Restart-ServiceAfterUptime', 'Wait-InstallationProcess', 'Start-ServiceWithRecovery', 'Get-CimOrWmiInstance'
        )
        $script:TestServiceSource = foreach ($name in $functionNames) {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if (-not $functionMatch.Success) {
                throw "Unable to extract $name from ConfigMgrClientHealth.ps1"
            }
            $functionMatch.Value
        }

        # Stubs shadow script functions and native executables so nothing reaches the real system.
        function Get-OperatingSystem {}
        function Get-ServiceUpTime { param($Name) }
        function sc.exe {}
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }
        function cmd {}

        function New-ServiceLog { [pscustomobject]@{ Services = 'OK' } }
    }

    BeforeEach {
        foreach ($source in $script:TestServiceSource) { Invoke-Expression $source }

        $PowerShellVersion = 7
        $script:ServiceStatus = 'Running'
        $script:ServiceStartType = 'Automatic'
        $script:WmiStartMode = 'Auto'
        $script:WmiStatus = 'OK'
        $script:DelayedAutostart = 0
        $script:ServiceUptimeDays = 1

        Mock Get-OperatingSystem { 'Windows 11 64-Bit' }
        Mock Get-ServiceUpTime { $script:ServiceUptimeDays }
        Mock Get-ItemProperty { [pscustomobject]@{ DelayedAutostart = $script:DelayedAutostart } }
        Mock Get-Service { [pscustomobject]@{ Name = [string]$Name; Status = $script:ServiceStatus; StartType = $script:ServiceStartType } }
        Mock Get-CimInstance { [pscustomobject]@{ StartMode = $script:WmiStartMode; Status = $script:WmiStatus; ProcessID = 4242 } }
        Mock Get-WmiObject { [pscustomobject]@{ StartMode = $script:WmiStartMode; Status = $script:WmiStatus; ProcessID = 4242 } }
        Mock Set-Service {}
        Mock Start-Service {}
        Mock Restart-Service {}
        Mock Stop-Process {}
        Mock Get-Process {}
        Mock Start-Sleep {}
        $script:Messages = [System.Collections.Generic.List[string]]::new()
        Mock Write-HostAndLog { $script:Messages.Add($Text) }
        Mock sc.exe { $script:NativeArgs = @($args) }
        Mock cmd { $script:NativeArgs = @($args) }
    }

    It 'reports OK and changes nothing when startup type and state already match' {
        $log = New-ServiceLog

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $output | Should -BeNullOrEmpty
        $script:Messages | Should -Be @('Service TestSvc01 startup: OK', 'Service TestSvc01 running: OK')
        $log.Services | Should -Be 'OK'
        Should -Invoke Set-Service -Times 0 -Exactly
        Should -Invoke Start-Service -Times 0 -Exactly
        Should -Invoke sc.exe -Times 0 -Exactly
    }

    It 'reads the current start mode through CIM with the service filter' {
        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log (New-ServiceLog) | Out-Null

        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $ClassName -eq 'Win32_Service' -and $Filter -eq "Name='TestSvc01'" -and ($Property -join ',') -eq 'StartMode,ProcessID,Status'
        }
    }

    It 'sets a different configured startup type with Set-Service' {
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'Manual' -State 'Running' -Log $log

        $script:Messages | Should -Contain 'Configuring service TestSvc01 StartupType to: Manual...'
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestSvc01' -and $StartupType -eq 'Manual' }
        $log.Services | Should -Be 'Started'
    }

    It 'uses sc.exe for delayed start when the service is automatic without the delay flag' {
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'automaticd' -State 'Running' -Log $log

        $script:Messages | Should -Contain 'Configuring service TestSvc01 StartupType to: Automatic (Delayed Start)...'
        Should -Invoke sc.exe -Times 1 -Exactly
        # The script passes the Get-Service object, which PowerShell converts to the service name for native commands.
        $script:NativeArgs[0] | Should -Be 'config'
        $script:NativeArgs[1].Name | Should -Be 'TestSvc01'
        $script:NativeArgs[2..3] | Should -Be @('start=', 'delayed-auto')
        Should -Invoke Set-Service -Times 0 -Exactly
        $log.Services | Should -Be 'Started'
    }

    It 'treats a delayed-start service with the delay flag as OK' {
        $script:DelayedAutostart = 1

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic (Delayed Start)' -State 'Running' -Log (New-ServiceLog)

        $script:Messages | Should -Contain 'Service TestSvc01 startup: OK'
        Should -Invoke sc.exe -Times 0 -Exactly
    }

    It 'sets wuauserv to Automatic instead of delayed start on Windows 11' {
        $script:ServiceStartType = 'Manual'
        $script:WmiStartMode = 'Manual'
        $log = New-ServiceLog

        Test-Service -Name 'wuauserv' -StartupType 'automaticd' -State 'Running' -Log $log

        $script:Messages | Should -Contain 'Configuring service wuauserv StartupType to: Automatic (Trigger Start)...'
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'wuauserv' -and $StartupType -eq 'Automatic' }
        Should -Invoke sc.exe -Times 0 -Exactly
        $log.Services | Should -Be 'OK'
    }

    It 'starts a stopped service' {
        $script:ServiceStatus = 'Stopped'
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $script:Messages | Should -Contain 'Starting service: TestSvc01...'
        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestSvc01' }
        Should -Invoke Stop-Process -Times 0 -Exactly
        $log.Services | Should -Be 'Started'
    }

    It 'stops the process of a degraded service before starting it' {
        $script:ServiceStatus = 'Stopped'
        $script:WmiStatus = 'Degraded'
        Mock Write-Warning {}

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log (New-ServiceLog) | Out-Null

        Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $Id -eq 4242 }
        Should -Invoke Start-Service -Times 1 -Exactly
    }

    It 'moves a service to its own thread and retries when it fails with error 1290' {
        $script:ServiceStatus = 'Stopped'
        $script:StartAttempts = 0
        Mock Start-Service {
            $script:StartAttempts++
            if ($script:StartAttempts -eq 1) {
                $exception = [System.Exception]::new('Service shares a thread with a protected service')
                $exception.HResult = -2146233087
                throw $exception
            }
        }
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $script:Messages | Should -Contain "Failed to start service TestSvc01 because it's sharing a thread with another process.  Changing to use its own thread."
        Should -Invoke cmd -Times 1 -Exactly
        $script:NativeArgs | Should -Be @('/c', 'sc', 'config', 'TestSvc01', 'type=', 'own')
        $script:StartAttempts | Should -Be 2
        $log.Services | Should -Be 'Started'
    }

    It 'restarts a running service whose uptime exceeds the configured limit' {
        $script:ServiceUptimeDays = 10
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Uptime 7 -Log $log

        $script:Messages | Should -Contain 'Restarted service: TestSvc01...'
        Should -Invoke Restart-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestSvc01' }
        $log.Services | Should -Be 'Restarted'
    }

    It 'reports uptime OK when the service is within the limit' {
        $script:ServiceUptimeDays = 3

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Uptime 7 -Log (New-ServiceLog)

        $script:Messages | Should -Contain 'Service TestSvc01 uptime: OK'
        Should -Invoke Restart-Service -Times 0 -Exactly
    }

    It 'does not restart the service when installation processes are still running after the wait' {
        $script:ServiceUptimeDays = 10
        Mock Wait-InstallationProcess { $false }
        $log = New-ServiceLog

        Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Uptime 7 -Log $log | Out-Null

        Should -Invoke Wait-InstallationProcess -Times 1 -Exactly -ParameterFilter { $WaitMinutes -eq 30 }
        Should -Invoke Restart-Service -Times 0 -Exactly
        $log.Services | Should -Be 'OK'
    }
}

Describe 'Wait-InstallationProcess' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Wait-InstallationProcess\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Wait-InstallationProcess from ConfigMgrClientHealth.ps1'
        }

        $script:WaitSource = $functionMatch.Value
    }

    BeforeEach {
        Invoke-Expression $script:WaitSource

        Mock Start-Sleep {}
        Mock Write-Warning {}
    }

    It 'returns true without waiting when no installation processes are running' {
        Mock Get-Process {}

        Wait-InstallationProcess -Name 'TestSvc01' -WaitMinutes 30 | Should -BeTrue

        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'returns false and warns when installation processes outlast the wait limit' {
        Mock Get-Process { @([pscustomobject]@{ Name = 'msiexec' }) }

        Wait-InstallationProcess -Name 'TestSvc01' -WaitMinutes 0 | Should -BeFalse

        Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like 'Timed out waiting 0 minutes*TestSvc01*' }
    }

    It 'waits and then returns true once installation processes finish' {
        $script:ProcessChecks = 0
        Mock Get-Process {
            $script:ProcessChecks++
            if ($script:ProcessChecks -eq 1) { @([pscustomobject]@{ Name = 'msiexec' }) }
        }

        Wait-InstallationProcess -Name 'TestSvc01' -WaitMinutes 30 | Should -BeTrue

        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 30 }
    }
}

Describe 'Console output' {
    It 'only calls Write-Host from Write-HostAndLog, so status messages also reach the logs' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:SourceFile, [ref]$null, [ref]$null)
        $callers = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] -and $args[0].GetCommandName() -eq 'Write-Host' }, $true) |
            ForEach-Object {
                $node = $_
                while ($node -and $node -isnot [System.Management.Automation.Language.FunctionDefinitionAst]) { $node = $node.Parent }
                if ($node) { $node.Name } else { "script line $($_.Extent.StartLineNumber)" }
            } | Sort-Object -Unique

        $callers | Should -Be 'Write-HostAndLog'
    }
}

Describe 'Write-HostAndLog' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $pattern = '(?ms)^\s*Function\s+Write-HostAndLog\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)'
        $functionMatch = [regex]::Match($sourceContent, $pattern)

        if (-not $functionMatch.Success) {
            throw 'Unable to extract Write-HostAndLog from ConfigMgrClientHealth.ps1'
        }

        $script:HostAndLogSource = $functionMatch.Value

        function Get-XMLConfigLoggingLocalFile {}
        function Get-XMLConfigLoggingEnable {}
        function Get-XMLConfigLoggingLevel {}
        function Out-LogFile { param($Xml, $Text, $Mode, $Severity) }
    }

    BeforeEach {
        Invoke-Expression $script:HostAndLogSource

        $script:Xml = $null
        $script:LocalFile = 'True'
        $script:FileEnable = 'True'
        $script:FileLevel = 'Full'

        Mock Get-XMLConfigLoggingLocalFile { $script:LocalFile }
        Mock Get-XMLConfigLoggingEnable { $script:FileEnable }
        Mock Get-XMLConfigLoggingLevel { $script:FileLevel }
        Mock Out-LogFile {}
        Mock Write-Host {}
    }

    It 'writes to the console, the local log, and the share log when all are enabled' {
        Write-HostAndLog -Text 'SMSTSMgr: OK'

        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'SMSTSMgr: OK' -and -not $ForegroundColor }
        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Mode -eq 'Local' -and $Text -eq 'SMSTSMgr: OK' -and $Severity -eq 1 }
        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { -not $Mode -and $Text -eq 'SMSTSMgr: OK' -and $Severity -eq 1 }
    }

    It 'passes the console color and severity through' {
        Write-HostAndLog -Text 'CcmSQLCE.log exists' -ForegroundColor Red -Severity 2

        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $ForegroundColor -eq 'Red' }
        Should -Invoke Out-LogFile -Times 2 -Exactly -ParameterFilter { $Severity -eq 2 }
    }

    It 'skips the share log when the file log level is not Full' {
        $script:FileLevel = 'ClientInstall'

        Write-HostAndLog -Text 'SMSTSMgr: OK'

        Should -Invoke Out-LogFile -Times 1 -Exactly
        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Mode -eq 'Local' }
    }

    It 'skips the share log when file logging is disabled' {
        $script:FileEnable = 'False'

        Write-HostAndLog -Text 'SMSTSMgr: OK'

        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Mode -eq 'Local' }
        Should -Invoke Out-LogFile -Times 0 -Exactly -ParameterFilter { -not $Mode }
    }

    It 'skips the local log when LocalLogFile is false' {
        $script:LocalFile = 'False'

        Write-HostAndLog -Text 'SMSTSMgr: OK'

        Should -Invoke Out-LogFile -Times 0 -Exactly -ParameterFilter { $Mode -eq 'Local' }
        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { -not $Mode }
    }

    It 'only writes to the console when no configuration is loaded' {
        $script:LocalFile = $null
        $script:FileEnable = $null
        $script:FileLevel = $null

        Write-HostAndLog -Text 'Configuration Manager Task Sequence detected on computer. Exiting script'

        Should -Invoke Write-Host -Times 1 -Exactly
        Should -Invoke Out-LogFile -Times 0 -Exactly
    }
}

Describe 'WMI query functions' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $functionNames = @(
            'Get-CimOrWmiInstance', 'Get-OSDiskFreeSpace', 'Test-DiskSpace', 'Test-AdminShare',
            'Get-ClientVersion', 'Get-Domain', 'Test-MissingDrivers'
        )
        $script:WmiQuerySource = foreach ($name in $functionNames) {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if (-not $functionMatch.Success) {
                throw "Unable to extract $name from ConfigMgrClientHealth.ps1"
            }
            $functionMatch.Value
        }

        # Get-WmiObject does not exist in PowerShell 7, so give the mock its real parameter shape.
        function Get-WmiObject {
            [CmdletBinding()]
            param([Parameter(Position = 0)][string]$Class, [string]$Namespace, [string]$Filter, [string[]]$Property)
        }
        function Get-XMLConfigOSDiskFreeSpace {}
        function Get-XMLConfigLoggingLevel {}
        function Out-LogFile { param($Xml, $Text, $Severity) }
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }

        # Fake WMI data. The mock honours a WQL -Filter of the form "Name='x' OR Name='y'" so the
        # same test passes whether the function filters in the query or with Where-Object afterwards.
        function Get-FakeWmiInstance {
            param($ClassName, $Filter)
            $data = @{
                Win32_LogicalDisk    = @(
                    [pscustomobject]@{ DeviceID = 'Z:'; FreeSpace = 90; Size = 100 },
                    [pscustomobject]@{ DeviceID = $env:SystemDrive; FreeSpace = $script:SystemDriveFree; Size = 200 }
                )
                Win32_Share          = @($script:Shares | ForEach-Object { [pscustomobject]@{ Name = $_ } })
                SMS_Client           = @([pscustomobject]@{ ClientVersion = '5.00.9128.1000' })
                Win32_ComputerSystem = @([pscustomobject]@{ Domain = 'contoso.example' })
                Win32_PNPEntity      = @($script:Devices)
            }
            $instances = $data[$ClassName]
            if ($Filter) {
                $wanted = [regex]::Matches($Filter, "(\w+)='([^']*)'") | ForEach-Object { [pscustomobject]@{ Property = $_.Groups[1].Value; Value = $_.Groups[2].Value } }
                $instances = $instances | Where-Object { $instance = $_; @($wanted | Where-Object { $instance.($_.Property) -eq $_.Value }).Count -gt 0 }
            }
            $instances
        }
    }

    BeforeEach {
        foreach ($source in $script:WmiQuerySource) { Invoke-Expression $source }

        $script:OriginalSystemDrive = $env:SystemDrive
        $env:SystemDrive = 'C:'
        $PowerShellVersion = 7
        $script:SystemDriveFree = 50
        $script:Shares = @('ADMIN$', 'C$', 'IPC$')
        $script:Devices = @()

        Mock Get-CimInstance { Get-FakeWmiInstance -ClassName $ClassName -Filter $Filter }
        Mock Get-WmiObject { Get-FakeWmiInstance -ClassName $Class -Filter $Filter }
        Mock Get-XMLConfigOSDiskFreeSpace { 10 }
        Mock Get-XMLConfigLoggingLevel { 'Full' }
        Mock Out-LogFile {}
        $script:Messages = [System.Collections.Generic.List[string]]::new()
        Mock Write-HostAndLog { $script:Messages.Add($Text) }
        Mock Stop-Service {}
        Mock Start-Service {}
    }

    AfterEach {
        $env:SystemDrive = $script:OriginalSystemDrive
    }

    Context 'Get-OSDiskFreeSpace' {
        It 'returns the system drive free space percentage on <Version>' -ForEach @(@{ Version = 7 }, @{ Version = 5 }) {
            $PowerShellVersion = $Version

            Get-OSDiskFreeSpace | Should -Be 25
        }
    }

    Context 'Test-DiskSpace' {
        It 'reports OK when free space is above the configured minimum' {
            Test-DiskSpace | Should -BeNullOrEmpty

            $script:Messages | Should -Be 'Free space C: OK'
        }

        It 'writes an error when free space is at or below the configured minimum' {
            $script:SystemDriveFree = 10
            $ErrorActionPreference = 'Stop'

            { Test-DiskSpace } | Should -Throw '*Local disk C: Less than 10 % free space*'
        }
    }

    Context 'Test-AdminShare' {
        It 'reports both shares OK without restarting the Server service on <Version>' -ForEach @(@{ Version = 7 }, @{ Version = 5 }) {
            $PowerShellVersion = $Version
            $log = [pscustomobject]@{ AdminShare = $null }

            Test-AdminShare -Log $log

            $script:Messages | Should -Be @('Adminshare Admin$: OK', 'Adminshare C$: OK')
            $log.AdminShare | Should -Be 'OK'
            Should -Invoke Stop-Service -Times 0 -Exactly
        }

        It 'restarts the Server service when the <Missing> share is missing' -ForEach @(@{ Missing = 'C$' }, @{ Missing = 'ADMIN$' }) {
            $script:Shares = @('ADMIN$', 'C$', 'IPC$') | Where-Object { $_ -ne $Missing }
            $log = [pscustomobject]@{ AdminShare = $null }

            Test-AdminShare -Log $log -WarningAction SilentlyContinue | Out-Null

            $log.AdminShare | Should -Be 'Repaired'
            Should -Invoke Stop-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'server' }
            Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'server' }
        }
    }

    Context 'Get-ClientVersion and Get-Domain' {
        It 'returns the client version and domain on <Version>' -ForEach @(@{ Version = 7 }, @{ Version = 5 }) {
            $PowerShellVersion = $Version

            Get-ClientVersion | Should -Be '5.00.9128.1000'
            Get-Domain | Should -Be 'contoso.example'
        }

        It 'returns false when the query throws' {
            Mock Get-CimInstance { throw 'Invalid namespace' }

            Get-ClientVersion | Should -BeFalse
            Get-Domain | Should -BeFalse
        }
    }

    Context 'Test-MissingDrivers' {
        It 'reports OK when no device has a driver problem' {
            $script:Devices = @(
                [pscustomobject]@{ Name = 'Disk'; DeviceID = 'D1'; ConfigManagerErrorCode = 0 },
                [pscustomobject]@{ Name = 'Disabled'; DeviceID = 'D2'; ConfigManagerErrorCode = 22 },
                [pscustomobject]@{ Name = 'PS/2 Keyboard'; DeviceID = 'D3'; ConfigManagerErrorCode = 28 }
            )
            $log = [pscustomobject]@{ Drivers = $null }

            Test-MissingDrivers -Log $log

            $script:Messages | Should -Be 'Drivers: OK'
            $log.Drivers | Should -Be 'OK'
        }

        It 'counts and logs devices with driver problems' {
            $script:Devices = @(
                [pscustomobject]@{ Name = 'Disk'; DeviceID = 'D1'; ConfigManagerErrorCode = 0 },
                [pscustomobject]@{ Name = 'Camera'; DeviceID = 'D4'; ConfigManagerErrorCode = 28 },
                [pscustomobject]@{ Name = 'Reader'; DeviceID = 'D5'; ConfigManagerErrorCode = 1 }
            )
            $log = [pscustomobject]@{ Drivers = $null }

            Test-MissingDrivers -Log $log -WarningAction SilentlyContinue | Out-Null

            $log.Drivers | Should -Be '2 unknown or faulty driver(s)'
            Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Text -eq 'Missing or faulty driver: Camera. Device ID: D4' }
            Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Text -eq 'Missing or faulty driver: Reader. Device ID: D5' }
        }
    }
}

Describe 'Client schedule triggers' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $script:ScheduleFunctions = @{
            'Get-SCCMPolicySourceUpdateMessage'     = '{00000000-0000-0000-0000-000000000032}'
            'Get-SCCMPolicySendUnsentStateMessages' = '{00000000-0000-0000-0000-000000000111}'
            'Get-SCCMPolicyScanUpdateSource'        = '{00000000-0000-0000-0000-000000000113}'
            'Get-SCCMPolicyHardwareInventory'       = '{00000000-0000-0000-0000-000000000001}'
            'Get-SCCMPolicyMachineEvaluation'       = '{00000000-0000-0000-0000-000000000022}'
        }
        # Invoke-ClientSchedule is optional so these tests also pass on the code before the helper existed.
        $script:ScheduleSource = foreach ($name in @($script:ScheduleFunctions.Keys) + 'Invoke-ClientSchedule') {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if ($functionMatch.Success) { $functionMatch.Value }
            elseif ($name -ne 'Invoke-ClientSchedule') { throw "Unable to extract $name from ConfigMgrClientHealth.ps1" }
        }

        # Invoke-WmiMethod does not exist in PowerShell 7, so give the mock its real parameter shape.
        function Invoke-WmiMethod {
            [CmdletBinding()]
            param([string]$Namespace, [string]$Class, [string]$Name, [object[]]$ArgumentList)
        }
    }

    BeforeEach {
        foreach ($source in $script:ScheduleSource) { Invoke-Expression $source }

        Mock Invoke-CimMethod {}
        Mock Invoke-WmiMethod {}
    }

    It '<Name> triggers its schedule with Invoke-CimMethod on PowerShell 6 or later' -ForEach @(
        @{ Name = 'Get-SCCMPolicySourceUpdateMessage'; Id = '{00000000-0000-0000-0000-000000000032}' },
        @{ Name = 'Get-SCCMPolicySendUnsentStateMessages'; Id = '{00000000-0000-0000-0000-000000000111}' },
        @{ Name = 'Get-SCCMPolicyScanUpdateSource'; Id = '{00000000-0000-0000-0000-000000000113}' },
        @{ Name = 'Get-SCCMPolicyHardwareInventory'; Id = '{00000000-0000-0000-0000-000000000001}' },
        @{ Name = 'Get-SCCMPolicyMachineEvaluation'; Id = '{00000000-0000-0000-0000-000000000022}' }
    ) {
        $PowerShellVersion = 7

        & $Name | Should -BeNullOrEmpty

        Should -Invoke Invoke-WmiMethod -Times 0 -Exactly
        Should -Invoke Invoke-CimMethod -Times 1 -Exactly -ParameterFilter {
            $Namespace -eq 'root\ccm' -and $ClassName -eq 'sms_client' -and $MethodName -eq 'TriggerSchedule' -and $Arguments.sScheduleID -eq $Id -and $ErrorAction -eq 'SilentlyContinue'
        }
    }

    It '<Name> triggers its schedule with Invoke-WmiMethod on Windows PowerShell' -ForEach @(
        @{ Name = 'Get-SCCMPolicySourceUpdateMessage'; Id = '{00000000-0000-0000-0000-000000000032}' },
        @{ Name = 'Get-SCCMPolicyMachineEvaluation'; Id = '{00000000-0000-0000-0000-000000000022}' }
    ) {
        $PowerShellVersion = 5

        & $Name | Should -BeNullOrEmpty

        Should -Invoke Invoke-CimMethod -Times 0 -Exactly
        Should -Invoke Invoke-WmiMethod -Times 1 -Exactly -ParameterFilter {
            $Namespace -eq 'root\ccm' -and $Class -eq 'sms_client' -and $Name -eq 'TriggerSchedule' -and $ArgumentList[0] -eq $Id -and $ErrorAction -eq 'SilentlyContinue'
        }
    }
}

Describe 'PowerShell 7 compatibility' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $functionNames = @(
            'Get-CimOrWmiInstance', 'Remove-CimOrWmiInstance', 'ConvertFrom-WmiDateTime', 'Get-SmallDateTime',
            'Get-ServiceUpTime', 'Test-ClientSettingsConfiguration', 'Get-LastReboot', 'Test-SCCMHardwareInventoryScan'
        )
        $script:CompatSource = foreach ($name in $functionNames) {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if (-not $functionMatch.Success) {
                throw "Unable to extract $name from ConfigMgrClientHealth.ps1"
            }
            $functionMatch.Value
        }

        # Windows PowerShell-only cmdlets do not exist in PowerShell 7, and the CIM cmdlets require real
        # CimInstance input, so these stubs give the mocks untyped parameters.
        function Get-WmiObject {
            [CmdletBinding()]
            param([Parameter(Position = 0)][string]$Class, [string]$Namespace, [string]$Filter, [string[]]$Property)
        }
        function Remove-WmiObject { [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)]$InputObject) }
        function Remove-CimInstance { [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)]$InputObject) }
        function Get-EventLog { [CmdletBinding()] param($LogName, $Source, $EntryType, $Message, $Newest) }
        function Get-XMLConfigLoggingTimeFormat {}
        function Get-DateTime {}
        function Get-XMLConfigMaxRebootDays {}
        function Get-XMLConfigRebootApplicationEnable {}
        function Start-RebootApplication {}
        function Get-XMLConfigHardwareInventoryDays {}
        function Get-XMLConfigHardwareInventoryFix {}
        function Get-SCCMPolicyHardwareInventory {}
        function Get-XMLConfigClientSettingsCheckFix {}
        function Write-HostAndLog { param($Text) }

        function ConvertTo-Dmtf { param([datetime]$Date) [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($Date) }
    }

    BeforeEach {
        foreach ($source in $script:CompatSource) { Invoke-Expression $source }

        $PowerShellVersion = 7
        Mock Get-XMLConfigLoggingTimeFormat { 'Local' }
        Mock Get-DateTime { 'no date' }
        Mock Write-HostAndLog {}
    }

    Context 'ConvertFrom-WmiDateTime' {
        It 'returns a [datetime] unchanged' {
            $date = Get-Date '2026-01-15 08:30:00'

            ConvertFrom-WmiDateTime -Date $date | Should -Be $date
        }

        It 'converts a DMTF string the same way ConvertToDateTime does' {
            $dmtf = '20260115083000.000000+000'

            ConvertFrom-WmiDateTime -Date $dmtf | Should -Be ([System.Management.ManagementDateTimeConverter]::ToDateTime($dmtf))
        }

        It 'returns nothing for an empty value' {
            ConvertFrom-WmiDateTime -Date $null | Should -BeNullOrEmpty
            ConvertFrom-WmiDateTime -Date '' | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-CimOrWmiInstance' {
        BeforeEach {
            Mock Remove-CimInstance {}
            Mock Remove-WmiObject {}
        }

        It 'removes each piped instance with Remove-CimInstance on PowerShell 6 or later' {
            @('a', 'b') | Remove-CimOrWmiInstance

            Should -Invoke Remove-CimInstance -Times 2 -Exactly
            Should -Invoke Remove-WmiObject -Times 0 -Exactly
        }

        It 'removes each piped instance with Remove-WmiObject on Windows PowerShell' {
            $PowerShellVersion = 5

            @('a', 'b') | Remove-CimOrWmiInstance

            Should -Invoke Remove-WmiObject -Times 2 -Exactly
            Should -Invoke Remove-CimInstance -Times 0 -Exactly
        }
    }

    Context 'Get-LastReboot' {
        BeforeEach {
            $script:Xml = [xml]'<Configuration><Option Name="RebootApplication" Enable="True" /></Configuration>'
            $script:BootTime = (Get-Date).AddDays(-2)
            Mock Get-XMLConfigMaxRebootDays { 7 }
            Mock Get-XMLConfigRebootApplicationEnable { 'True' }
            Mock Start-RebootApplication {}
            Mock Get-CimInstance { [pscustomobject]@{ LastBootUpTime = $script:BootTime } }
            Mock Get-WmiObject { [pscustomobject]@{ LastBootUpTime = (ConvertTo-Dmtf $script:BootTime) } }
        }

        It 'reports a recent boot as OK on PowerShell <Version>' -ForEach @(@{ Version = 7 }, @{ Version = 5 }) {
            $PowerShellVersion = $Version

            Get-LastReboot -Xml $script:Xml | Should -BeNullOrEmpty

            Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -like 'Last boot time: *: OK' }
            Should -Invoke Start-RebootApplication -Times 0 -Exactly
        }

        It 'starts the reboot application when the last boot is older than MaxRebootDays on PowerShell 7' {
            $script:BootTime = (Get-Date).AddDays(-30)

            Get-LastReboot -Xml $script:Xml -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null

            $warnings | Should -BeLike '*More than 7 days since last reboot. Starting reboot application.'
            Should -Invoke Start-RebootApplication -Times 1 -Exactly
        }

        It 'does not start the reboot application when the RebootApplication getter returns <Value>' -ForEach @(@{ Value = 'False' }, @{ Value = $null }) {
            $script:BootTime = (Get-Date).AddDays(-30)
            $script:RebootEnable = $Value
            Mock Get-XMLConfigRebootApplicationEnable { $script:RebootEnable }

            Get-LastReboot -Xml $script:Xml -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null

            $warnings | Should -BeLike '*More than 7 days since last reboot. Reboot application disabled.'
            Should -Invoke Start-RebootApplication -Times 0 -Exactly
        }
    }

    Context 'Test-SCCMHardwareInventoryScan' {
        BeforeEach {
            $script:ScanTime = Get-Date '2026-01-15 08:30:00'
            Mock Get-XMLConfigHardwareInventoryDays { 7 }
            Mock Get-XMLConfigHardwareInventoryFix { 'False' }
            Mock Get-SCCMPolicyHardwareInventory {}
            Mock Get-CimInstance {
                [pscustomobject]@{ InventoryActionID = '{00000000-0000-0000-0000-000000000002}'; LastCycleStartedDate = (Get-Date '2020-01-01') },
                [pscustomobject]@{ InventoryActionID = '{00000000-0000-0000-0000-000000000001}'; LastCycleStartedDate = $script:ScanTime }
            }
            Mock Get-WmiObject {
                [pscustomobject]@{ InventoryActionID = '{00000000-0000-0000-0000-000000000002}'; LastCycleStartedDate = (ConvertTo-Dmtf (Get-Date '2020-01-01')) },
                [pscustomobject]@{ InventoryActionID = '{00000000-0000-0000-0000-000000000001}'; LastCycleStartedDate = (ConvertTo-Dmtf $script:ScanTime) }
            }
        }

        It 'records the last hardware inventory scan date on PowerShell <Version>' -ForEach @(@{ Version = 7 }, @{ Version = 5 }) {
            $PowerShellVersion = $Version
            $log = [pscustomobject]@{ HWInventory = $null }

            Test-SCCMHardwareInventoryScan -Log $log | Out-Null

            $log.HWInventory | Should -Be '2026-01-15 08:30:00'
            Should -Invoke Get-SCCMPolicyHardwareInventory -Times 0 -Exactly
        }

        It 'reports OK when the scan is newer than the configured number of days' {
            $script:ScanTime = (Get-Date).AddDays(-1)
            $log = [pscustomobject]@{ HWInventory = $null }

            Test-SCCMHardwareInventoryScan -Log $log | Should -BeNullOrEmpty

            Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'ConfigMgr Hardware Inventory scan: OK' }
        }
    }

    Context 'Test-ClientSettingsConfiguration' {
        BeforeEach {
            $script:Policies = [System.Collections.Generic.List[object]]::new()
            foreach ($source in 'CcmTaskSequence', 'CcmTaskSequence', 'Local') { $script:Policies.Add([pscustomobject]@{ PolicySource = $source }) }
            Mock Get-XMLConfigClientSettingsCheckFix { 'True' }
            Mock Get-CimInstance { @($script:Policies) }
            Mock Get-WmiObject { @($script:Policies) }
            Mock Remove-CimInstance { [void]$script:Policies.Remove($InputObject) }
            Mock Remove-WmiObject { [void]$script:Policies.Remove($InputObject) }
        }

        It 'removes task sequence client settings on PowerShell 7' {
            $log = [pscustomobject]@{ ClientSettings = $null }

            Test-ClientSettingsConfiguration -Log $log

            $log.ClientSettings | Should -Be 'Remediated'
            Should -Invoke Remove-CimInstance -Times 2 -Exactly
            Should -Invoke Get-CimInstance -ParameterFilter { $ClassName -eq 'CCM_ClientAgentConfig' -and $Namespace -eq 'root\ccm\Policy\DefaultMachine\RequestedConfig' }
            $script:Policies.PolicySource | Should -Be @('Local')
        }

        It 'removes task sequence client settings on Windows PowerShell' {
            $PowerShellVersion = 5
            $log = [pscustomobject]@{ ClientSettings = $null }

            Test-ClientSettingsConfiguration -Log $log

            $log.ClientSettings | Should -Be 'Remediated'
            Should -Invoke Remove-WmiObject -Times 2 -Exactly
        }

        It 'reports OK when no task sequence client settings exist' {
            $script:Policies.RemoveAt(0); $script:Policies.RemoveAt(0)
            $log = [pscustomobject]@{ ClientSettings = $null }

            Test-ClientSettingsConfiguration -Log $log

            $log.ClientSettings | Should -Be 'OK'
            Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'ClientSettings: OK' }
        }
    }

    Context 'Get-ServiceUpTime' {
        BeforeEach {
            Mock Get-Service { [pscustomobject]@{ Name = 'TestSvc01'; DisplayName = 'Test Service 01' } }
            Mock Get-EventLog { [pscustomobject]@{ TimeGenerated = (Get-Date).AddDays(-4).AddMinutes(-5) } }
            Mock Get-WinEvent {
                [pscustomobject]@{ Message = 'The Other Service service entered the running state.'; TimeCreated = (Get-Date).AddMinutes(-5) },
                [pscustomobject]@{ Message = 'The Test Service 01 service entered the running state.'; TimeCreated = (Get-Date).AddDays(-3).AddMinutes(-5) }
            }
            Mock Get-CimInstance { [pscustomobject]@{ ProcessID = 4242 } }
            Mock Get-Process { [pscustomobject]@{ StartTime = (Get-Date).AddDays(-5).AddMinutes(-5) } }
        }

        It 'reads the last start event with Get-WinEvent on PowerShell 7' {
            Get-ServiceUpTime -Name 'TestSvc01' | Should -Be 3

            Should -Invoke Get-EventLog -Times 0 -Exactly
            Should -Invoke Get-WinEvent -Times 1 -Exactly -ParameterFilter {
                $FilterHashtable.LogName -eq 'System' -and $FilterHashtable.ProviderName -eq 'Service Control Manager' -and $FilterHashtable.Id -eq 7036
            }
        }

        It 'falls back to the service process start time when no start event matches' {
            Mock Get-WinEvent { [pscustomobject]@{ Message = 'The Other Service service entered the running state.'; TimeCreated = (Get-Date) } }

            Get-ServiceUpTime -Name 'TestSvc01' | Should -Be 5
        }

        It 'still uses Get-EventLog on Windows PowerShell' {
            $PowerShellVersion = 5
            Mock Get-WmiObject { [pscustomobject]@{ ProcessID = 4242 } }

            Get-ServiceUpTime -Name 'TestSvc01' | Should -Be 4

            Should -Invoke Get-WinEvent -Times 0 -Exactly
        }
    }
}

Describe 'Test-ConfigMgrClient' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $functionNames = @(
            'Test-ConfigMgrClient', 'Test-ClientDatabase', 'Start-ClientService', 'Test-ClientWMIConnection', 'Repair-ConfigMgrClient',
            'Install-ConfigMgrClient', 'Get-CimOrWmiInstance', 'Remove-CimOrWmiInstance', 'New-ClientInstalledReason'
        )
        $script:ConfigMgrClientSource = foreach ($name in $functionNames) {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if (-not $functionMatch.Success) {
                throw "Unable to extract $name from ConfigMgrClientHealth.ps1"
            }
            $functionMatch.Value
        }

        # Stubs shadow script functions and cmdlets that are missing or strictly typed in PowerShell 7.
        function Remove-CimInstance { [CmdletBinding()] param([Parameter(ValueFromPipeline = $true)]$InputObject) }
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }
        # Typed like the real function so a positional message fails to bind to -Xml.
        function Out-LogFile { param([xml]$Xml, $Text, $Mode, $Severity) }
        function Test-CcmSDF {}
        function Test-CcmSQLCELog {}
        function Get-XMLConfigCcmSQLCELog {}
        function Test-CCMSetup1 {}
        function Resolve-Client { param($Xml, $ClientInstallProperties, $FirstInstall, $Uninstall) }
        function Get-SmallDateTime {}

        function New-ClientLog { [pscustomobject]@{ ClientInstalledReason = $null; ClientInstalled = $null } }
    }

    BeforeEach {
        foreach ($source in $script:ConfigMgrClientSource) { Invoke-Expression $source }

        $PowerShellVersion = 7
        $script:ServiceStatus = 'Running'
        $script:ServiceStartType = 'Automatic'
        $script:ServiceInstalled = $true
        $script:SdfPresent = $true
        $script:SqlCeLogEnable = 'False'
        $script:SqlCeCorrupt = $false
        $script:WmiBroken = $false

        Mock Get-Service {
            if ($script:ServiceInstalled) { [pscustomobject]@{ Name = 'CcmExec'; Status = $script:ServiceStatus; StartType = $script:ServiceStartType } }
        }
        Mock Get-CimInstance -ParameterFilter { $ClassName -eq 'SMS_Client' } {
            if ($script:WmiBroken) { throw 'Invalid namespace' }
            [pscustomobject]@{ ClientVersion = '5.00.9012.1010' }
        }
        Mock Get-CimInstance -ParameterFilter { $ClassName -eq '__Namespace' } { [pscustomobject]@{ Name = 'CCM' } }
        Mock Remove-CimInstance {}
        Mock Write-HostAndLog {}
        Mock Out-LogFile {}
        Mock Test-CcmSDF { $script:SdfPresent }
        Mock Test-CcmSQLCELog { $script:SqlCeCorrupt }
        Mock Get-XMLConfigCcmSQLCELog { $script:SqlCeLogEnable }
        Mock Test-CCMSetup1 {}
        Mock Resolve-Client {}
        Mock Get-SmallDateTime { '2026-01-15 08:30:00' }
        Mock Set-Service {}
        Mock Start-Service {}
        Mock Start-Sleep {}
    }

    It 'leaves a healthy client alone' {
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'Configuration Manager Client is installed' }
        Should -Invoke Resolve-Client -Times 0 -Exactly
        Should -Invoke Remove-CimInstance -Times 0 -Exactly
        $log.ClientInstalledReason | Should -BeNullOrEmpty
        $log.ClientInstalled | Should -BeNullOrEmpty
    }

    It 'reinstalls the client when its database files are missing' {
        $script:SdfPresent = $false
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        $log.ClientInstalledReason | Should -Be 'ConfigMgr Client database files missing.'
        Should -Invoke Test-CCMSetup1 -Times 1 -Exactly
        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $FirstInstall -eq $false }
        Should -Invoke Start-Sleep -Times 1 -Exactly
        $log.ClientInstalled | Should -Be '2026-01-15 08:30:00'
    }

    It 'clears the CCM namespace and reinstalls when SMS_Client cannot be read' {
        $script:WmiBroken = $true
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter { $ClassName -eq '__Namespace' -and $Namespace -eq 'root' -and $Filter -eq "Name='CCM'" }
        Should -Invoke Remove-CimInstance -Times 1 -Exactly
        $log.ClientInstalledReason | Should -Be 'Failed to connect to SMS_Client WMI class.'
        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $FirstInstall -eq $false }
    }

    It 'records every reason when several checks fail' {
        $script:SdfPresent = $false
        $script:WmiBroken = $true
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        $log.ClientInstalledReason | Should -Be 'ConfigMgr Client database files missing. Failed to connect to SMS_Client WMI class.'
        Should -Invoke Resolve-Client -Times 1 -Exactly
    }

    It 'installs the client when the CcmExec service does not exist' {
        $script:ServiceInstalled = $false
        Mock Resolve-Client { $script:ServiceInstalled = $true }
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'Configuration Manager client is not installed. Installing...' }
        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $FirstInstall -eq $true }
        $log.ClientInstalledReason | Should -Be 'No agent found.'
        $log.ClientInstalled | Should -Be '2026-01-15 08:30:00'
        Should -Invoke Out-LogFile -Times 0 -Exactly
    }

    It 'logs a failed install to the share log when the agent is still missing' {
        $script:ServiceInstalled = $false

        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Out-LogFile -Times 1 -Exactly -ParameterFilter { $Mode -eq 'ClientInstall' -and $Severity -eq 3 }
    }

    It 'skips the CcmSQLCE.log check when CcmSQLCELog is disabled' {
        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Test-CcmSQLCELog -Times 0 -Exactly
    }

    It 'reinstalls the client when CcmSQLCELog is enabled and the database is corrupt' {
        $script:SqlCeLogEnable = 'True'
        $script:SqlCeCorrupt = $true
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        Should -Invoke Test-CcmSQLCELog -Times 1 -Exactly
        $log.ClientInstalledReason | Should -Be 'ConfigMgr Client database corrupt.'
        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $FirstInstall -eq $false }
    }

    It 'starts a stopped CcmExec service when the CcmSQLCELog check is <Case>' -ForEach @(@{ Case = 'disabled'; Enable = 'False' }, @{ Case = 'enabled'; Enable = 'True' }) {
        $script:SqlCeLogEnable = $Enable
        $script:ServiceStatus = 'Stopped'

        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Start-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'CcmExec' }
        Should -Invoke Set-Service -Times 0 -Exactly
        Should -Invoke Resolve-Client -Times 0 -Exactly
    }

    It 'sets a stopped CcmExec service to Automatic before starting it' {
        $script:ServiceStatus = 'Stopped'
        $script:ServiceStartType = 'Disabled'

        Test-ConfigMgrClient -Log (New-ClientLog) | Out-Null

        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'CcmExec' -and $StartupType -eq 'Automatic' }
        Should -Invoke Start-Service -Times 1 -Exactly
    }

    It 'does not start CcmExec when the database files are missing' {
        $script:ServiceStatus = 'Stopped'
        $script:SdfPresent = $false

        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Start-Service -Times 0 -Exactly
    }

    It 'reinstalls the client when CcmExec fails to start' {
        $script:ServiceStatus = 'Stopped'
        Mock Start-Service { Write-Error 'Cannot start service CcmExec' }
        $log = New-ClientLog

        Test-ConfigMgrClient -Log $log

        $log.ClientInstalledReason | Should -Be 'Service not running, failed to start.'
        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $FirstInstall -eq $false }
    }

    It 'uninstalls before reinstalling when the database is <Case>' -ForEach @(
        @{ Case = 'missing'; SdfPresent = $false; Enable = 'False'; Corrupt = $false },
        @{ Case = 'corrupt'; SdfPresent = $true; Enable = 'True'; Corrupt = $true }
    ) {
        $script:SdfPresent = $SdfPresent
        $script:SqlCeLogEnable = $Enable
        $script:SqlCeCorrupt = $Corrupt

        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $Uninstall -eq $true }
    }

    It 'reinstalls without uninstalling when only <Case> fails' -ForEach @(@{ Case = 'the SMS_Client check' }, @{ Case = 'the CcmExec start' }) {
        if ($Case -eq 'the SMS_Client check') { $script:WmiBroken = $true }
        else { $script:ServiceStatus = 'Stopped'; Mock Start-Service { Write-Error 'Cannot start service CcmExec' } }

        Test-ConfigMgrClient -Log (New-ClientLog)

        Should -Invoke Resolve-Client -Times 1 -Exactly -ParameterFilter { $Uninstall -eq $false }
    }
}

Describe 'Test-DNSConfiguration' {
    BeforeAll {
        $sourceContent = Get-Content -Path $script:SourceFile -Raw
        $functionNames = @('Test-DNSConfiguration', 'Compare-DNSRecord', 'Repair-DNSRegistration', 'Get-CimOrWmiInstance')
        $script:DnsSource = foreach ($name in $functionNames) {
            $pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
            $functionMatch = [regex]::Match($sourceContent, $pattern)
            if (-not $functionMatch.Success) {
                throw "Unable to extract $name from ConfigMgrClientHealth.ps1"
            }
            $functionMatch.Value
        }

        # Get-DNSHostRecord wraps the [System.Net.Dns] lookups, so the tests replace it instead of querying the host's DNS.
        function Get-DNSHostRecord {}
        function Get-XMLConfigDNSFix {}
        function Out-LogFile { param([xml]$Xml, $Text, $Mode, $Severity) }
        function Write-HostAndLog { param($Text, $ForegroundColor, $Severity) }
        function Register-DnsClient {}
        function ipconfig {}
    }

    BeforeEach {
        foreach ($source in $script:DnsSource) { Invoke-Expression $source }

        $PowerShellVersion = 7
        $script:DnsFix = 'True'
        $script:Record = [pscustomobject]@{ Fqdn = 'pc01.contoso.com'; HostName = 'pc01.contoso.com'; AddressList = @('10.0.0.5') }

        Mock Get-DNSHostRecord { $script:Record }
        Mock Get-CimInstance { [pscustomobject]@{ IPAddress = @('10.0.0.5', 'fe80::1') } }
        Mock Get-XMLConfigDNSFix { $script:DnsFix }
        Mock Out-LogFile {}
        Mock Write-HostAndLog {}
        Mock Register-DnsClient {}
        Mock ipconfig {}
        Mock Write-Host {}
    }

    It 'reports OK when DNS publishes only local IP addresses' {
        $log = [pscustomobject]@{ DNS = $null }

        Test-DNSConfiguration -Log $log | Should -BeNullOrEmpty

        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'DNS Check: OK' -and -not $Severity }
        $log.DNS | Should -Be 'OK'
        Should -Invoke Register-DnsClient -Times 0 -Exactly
        Should -Invoke Get-CimInstance -Times 1 -Exactly -ParameterFilter {
            $ClassName -eq 'Win32_NetworkAdapterConfiguration' -and $Filter -eq 'IPEnabled=True' -and ($Property -join ',') -eq 'IPAddress'
        }
    }

    It 're-registers with DNS when DNS publishes an IP address the computer does not have' {
        $script:Record.AddressList = @('10.0.0.5', '10.0.0.9')
        $log = [pscustomobject]@{ DNS = $null }

        Test-DNSConfiguration -Log $log

        $log.DNS | Should -Be '10.0.0.9 '
        Should -Invoke Register-DnsClient -Times 1 -Exactly
        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -like '*Trying to resolve by registerting with DNS server' -and $Severity -eq 2 }
        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq "IP '10.0.0.9' in DNS record do not exist locally" -and $Severity -eq 2 }
    }

    It 'leaves the log files to Write-HostAndLog instead of writing the share log directly' {
        $script:Record.AddressList = @('10.0.0.9')

        Test-DNSConfiguration -Log ([pscustomobject]@{ DNS = $null })

        Should -Invoke Out-LogFile -Times 0 -Exactly
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'reports the DNS host name and addresses when DNS returns another host name' {
        $script:Record.HostName = 'pc02.contoso.com'

        Test-DNSConfiguration -Log ([pscustomobject]@{ DNS = $null })

        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq 'DNS name: pc02.contoso.com local fqdn: pc01.contoso.com DNS IPs: 10.0.0.5 Local IPs: 10.0.0.5 fe80::1' -and $Severity -eq 2 }
        Should -Invoke Register-DnsClient -Times 1 -Exactly
    }

    It 'uses ipconfig to re-register on PowerShell 3' {
        $PowerShellVersion = 3
        $script:Record.AddressList = @('10.0.0.9')

        Test-DNSConfiguration -Log ([pscustomobject]@{ DNS = $null })

        Should -Invoke ipconfig -Times 1 -Exactly
        Should -Invoke Register-DnsClient -Times 0 -Exactly
    }

    It 'only reports the mismatch in monitor mode' {
        $script:DnsFix = 'False'
        $script:Record.AddressList = @('10.0.0.9')
        $log = [pscustomobject]@{ DNS = $null }

        Test-DNSConfiguration -Log $log

        $log.DNS | Should -Be '10.0.0.9 '
        Should -Invoke Register-DnsClient -Times 0 -Exactly
        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -like '*Monitor mode only, no remediation' -and $Severity -eq 2 }
        Should -Invoke Write-HostAndLog -Times 1 -Exactly -ParameterFilter { $Text -eq "IP '10.0.0.9' in DNS record do not exist locally" }
    }

    It 'fails the check when DNS returns another host name' {
        $script:Record.HostName = 'pc02.contoso.com'

        $result = Compare-DNSRecord -Record $script:Record -LocalIPs @('10.0.0.5')

        $result.Match | Should -BeFalse
        $result.DnsFail | Should -Be 'DNS name: pc02.contoso.com local fqdn: pc01.contoso.com DNS IPs: 10.0.0.5 Local IPs: 10.0.0.5'
        $result.LogFail | Should -Be ''
    }

    It 'lists every DNS address that is not local' {
        $script:Record.AddressList = @('10.0.0.8', '10.0.0.5', '10.0.0.9')

        $result = Compare-DNSRecord -Record $script:Record -LocalIPs @('10.0.0.5')

        $result.Match | Should -BeFalse
        $result.LogFail | Should -Be '10.0.0.8 10.0.0.9 '
    }
}
