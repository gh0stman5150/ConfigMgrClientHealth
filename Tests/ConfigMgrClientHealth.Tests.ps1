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
        Mock sc.exe { $script:NativeArgs = @($args) }
        Mock cmd { $script:NativeArgs = @($args) }
    }

    It 'reports OK and changes nothing when startup type and state already match' {
        $log = New-ServiceLog

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $output | Should -Be @('Service TestSvc01 startup: OK', 'Service TestSvc01 running: OK')
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

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Manual' -State 'Running' -Log $log

        $output | Should -Contain 'Configuring service TestSvc01 StartupType to: Manual...'
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestSvc01' -and $StartupType -eq 'Manual' }
        $log.Services | Should -Be 'Started'
    }

    It 'uses sc.exe for delayed start when the service is automatic without the delay flag' {
        $log = New-ServiceLog

        $output = Test-Service -Name 'TestSvc01' -StartupType 'automaticd' -State 'Running' -Log $log

        $output | Should -Contain 'Configuring service TestSvc01 StartupType to: Automatic (Delayed Start)...'
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

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic (Delayed Start)' -State 'Running' -Log (New-ServiceLog)

        $output | Should -Contain 'Service TestSvc01 startup: OK'
        Should -Invoke sc.exe -Times 0 -Exactly
    }

    It 'sets wuauserv to Automatic instead of delayed start on Windows 11' {
        $script:ServiceStartType = 'Manual'
        $script:WmiStartMode = 'Manual'
        $log = New-ServiceLog

        $output = Test-Service -Name 'wuauserv' -StartupType 'automaticd' -State 'Running' -Log $log

        $output | Should -Contain 'Configuring service wuauserv StartupType to: Automatic (Trigger Start)...'
        Should -Invoke Set-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'wuauserv' -and $StartupType -eq 'Automatic' }
        Should -Invoke sc.exe -Times 0 -Exactly
        $log.Services | Should -Be 'OK'
    }

    It 'starts a stopped service' {
        $script:ServiceStatus = 'Stopped'
        $log = New-ServiceLog

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $output | Should -Contain 'Starting service: TestSvc01...'
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

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Log $log

        $output | Should -Contain "Failed to start service TestSvc01 because it's sharing a thread with another process.  Changing to use its own thread."
        Should -Invoke cmd -Times 1 -Exactly
        $script:NativeArgs | Should -Be @('/c', 'sc', 'config', 'TestSvc01', 'type=', 'own')
        $script:StartAttempts | Should -Be 2
        $log.Services | Should -Be 'Started'
    }

    It 'restarts a running service whose uptime exceeds the configured limit' {
        $script:ServiceUptimeDays = 10
        $log = New-ServiceLog

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Uptime 7 -Log $log

        $output | Should -Contain 'Restarted service: TestSvc01...'
        Should -Invoke Restart-Service -Times 1 -Exactly -ParameterFilter { $Name -eq 'TestSvc01' }
        $log.Services | Should -Be 'Restarted'
    }

    It 'reports uptime OK when the service is within the limit' {
        $script:ServiceUptimeDays = 3

        $output = Test-Service -Name 'TestSvc01' -StartupType 'Automatic' -State 'Running' -Uptime 7 -Log (New-ServiceLog)

        $output | Should -Contain 'Service TestSvc01 uptime: OK'
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
