# ConfigMgrClientHealth repository guidance

This is the single source of repository guidance for AI assistants. [CLAUDE.md](../CLAUDE.md) imports it, and [AGENTS.md](AGENTS.md) only lists files. PowerShell and Pester style rules are in [instructions/](instructions/).

## What this is

A single-script, Windows-only tool that checks and repairs Configuration Manager (SCCM/MEMCM) client health on the local endpoint. It runs elevated (local admin, ideally SYSTEM). It is not a module and has no build step.

- [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1): the whole implementation
- [config.xml](../config.xml): sample runtime config; this is the behavior contract
- [CreateDatabase.sql](../CreateDatabase.sql): `ClientHealth` SQL schema that the log object is written to
- [Download/](../Download/): packaged release and webservice artifacts; don't edit them

## Safety

**Never run `ConfigMgrClientHealth.ps1` itself, or dot-source it, as a validation or test step.** It really remediates the machine (services, WMI, registry, client reinstall) and has no dry-run or Apply switch. `SupportsShouldProcess` does not make every operation preview-safe. Manual runs belong only in an explicitly authorized non-production environment. Don't claim live CM, SQL, or webservice validation unless you actually ran it.

## Commands

Tests use the Pester version pinned in [workspace-tests.yml](workflows/workspace-tests.yml) (currently 6.2.0). CI runs `pwsh` on `windows-latest`.

```powershell
# Install the pinned Pester version
Install-Module -Name Pester -RequiredVersion 6.2.0 -Force -Scope CurrentUser

# Run all tests from the repo root
Invoke-Pester -Path ./Tests -Output Detailed

# Run a single Describe/It by name
$c = New-PesterConfiguration; $c.Run.Path = './Tests'; $c.Filter.FullName = '*Get-OperatingSystem*'; $c.Output.Verbosity = 'Detailed'; Invoke-Pester -Configuration $c

# Check that the script parses
$e = $null; [System.Management.Automation.Language.Parser]::ParseFile("$PWD\ConfigMgrClientHealth.ps1", [ref]$null, [ref]$e) | Out-Null; $e

# Check that the XML is well formed
[xml](Get-Content ./config.xml -Raw) | Out-Null
```

Report the PowerShell and Pester versions and the pass/fail counts you actually got.

## Script architecture

The script is one `[CmdletBinding()]` script with `Begin` / `Process` / `End` blocks:

- **Begin**: sets `$Version`, `$PowerShellVersion`, and `$global:ScriptPath`. If neither `-Config` nor `-Webservice` is passed, it defaults `$Config` to `Config.xml` next to the script. It validates and loads the XML into `$Xml`, then defines about 150 functions *inside the Begin block*. These functions share script-level state implicitly (`$Xml`, `$config`, `$PowerShellVersion`, `$global:ScriptPath`) rather than taking it as parameters.
- **Process**: runs the health checks in order: admin check, task-sequence check (exits 2), WMI, compliance-state refresh, client install/version, services, site code, cache, log size, provisioning mode, certificate, HW inventory, metering, DNS, BITS, and so on. Most checks run only when their `config.xml` toggle is on. Each `Test-*` function records its result on a shared `$Log` object from `New-LogObject` and may set flags such as `$reinstall` / `$restartCCMExec` that later steps act on.
- **End**: writes `LastRun` to `HKLM:\Software\ConfigMgrClientHealth`, then writes `$Log` to the local log file, the share log file, SQL (`Update-SQL`, only when `-Webservice` is not given), or the webservice (`Update-Webservice`).

Key function families:

- `Get-XMLConfig*`: thin accessors over `$Xml`, usually one per element or attribute. Many fall back to a default (for example, the share defaults to `$global:ScriptPath`).
- `Test-*` / `Repair-*` / `Resolve-Client`: detection and remediation.
- `Out-LogFile`: CMTrace-format logging. For a status message an operator should see, use `Write-HostAndLog`, which prints it and writes it to the local and share logs under the same config rules as the End block. Use `Write-Verbose` for diagnostics. Don't add bare `Write-Host` calls.
- `Get-CimOrWmiInstance`: queries a WMI class with `Get-CimInstance` on PowerShell 6+ or `Get-WmiObject` on Windows PowerShell. Use it for new class queries instead of another `if ($PowerShellVersion -ge 6)` pair, and pass a WQL `-Filter` rather than piping every instance to `Where-Object` when the filter is exact.
- `Remove-CimOrWmiInstance` and `ConvertFrom-WmiDateTime`: the matching delete and date conversion for those results. Don't call `Get-WmiObject`, `Remove-WmiObject`, `Get-EventLog`, or a result's `ConvertToDateTime()` method directly; they don't exist in PowerShell 7.
- `Invoke-ClientSchedule`: triggers a ConfigMgr client schedule by ID through `Invoke-CimMethod` or `Invoke-WmiMethod`. The `Get-SCCMPolicy*` functions wrap it.

**Coupled contracts:** `$Log` property names map to columns in `CreateDatabase.sql` and to the webservice payload. XML element and attribute names map to the `Get-XMLConfig*` getters. When you rename or add one, update every place it appears, or keep existing names unchanged.

## Test architecture

[Tests/ConfigMgrClientHealth.Tests.ps1](../Tests/ConfigMgrClientHealth.Tests.ps1) never dot-sources the script. Each test extracts individual functions with a regex and `Invoke-Expression`s them:

```powershell
$pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
```

Tests set the implicit state the function expects (`$script:Xml`, `$script:config`, `$global:ScriptPath`, `$PowerShellVersion`) and `Mock` every external effect (CIM/WMI, services, registry, `Test-Path`, `Invoke-RestMethod`, SQL). Extract or mock any other script function the code calls. Tests must not depend on the host OS.

Because the regex keys on a line starting `Function Name {` and ends at the closing brace followed by the next `Function`, keep that layout. Put a function's comments inside its body, not between functions.

## Coding rules

- Keep the XML-driven config contract; don't replace config values with hidden defaults.
- Keep the script self-contained. Local helper functions are fine; don't add shared modules or reference helpers that don't exist here.
- Match the existing style, use full cmdlet names, and avoid rewriting code that doesn't need to change.
- Preserve `$Log` property names, XML element names, and local file, SQL, and webservice behavior unless the task is to change that contract.
- Treat missing share access or SQL connectivity as configuration problems, not success.

## Security

- Don't add real hostnames, users, or share paths to examples, docs, or default config. Use placeholders.
- Don't log secrets or write them to configuration files.
- Don't add credential or silent-auth flows. SQL uses integrated auth.
- Don't claim support for platforms or workflows the repo doesn't implement.

## Documentation and pull requests

- Keep [README.md](../README.md) in sync when config elements, logging, or remediation behavior change.
- Link to authoritative files instead of copying guidance between docs.
- Keep pull requests scoped to this repository. Explain the reason for config or behavior changes, and list anything not validated or specific to an environment.
