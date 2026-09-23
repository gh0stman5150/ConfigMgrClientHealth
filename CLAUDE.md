# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Authoritative repo guidance lives in [.github/copilot-instructions.md](.github/copilot-instructions.md) and [.github/AGENTS.md](.github/AGENTS.md); this file summarizes what matters most. PowerShell and Pester style rules are in [.github/instructions/](.github/instructions/).

## What this is

A single-script, Windows-only remediation tool that checks and repairs Configuration Manager (SCCM/MEMCM) client health on the local endpoint. It is designed to run elevated (local admin, ideally SYSTEM). It is not a module and has no build step.

- [ConfigMgrClientHealth.ps1](ConfigMgrClientHealth.ps1): the whole implementation (~3600 lines)
- [config.xml](config.xml): sample runtime config; this is the behavior contract
- [CreateDatabase.sql](CreateDatabase.sql): `ClientHealth` SQL schema that the log object is written to
- `*.zip` / [Download/](Download/): packaged release and webservice artifacts; don't edit them

## Commands

Tests use Pester 6.2.0, pinned in [.github/workflows/workspace-tests.yml](.github/workflows/workspace-tests.yml). CI runs `pwsh` on `windows-latest`.

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

**Never run `ConfigMgrClientHealth.ps1` itself as a validation step.** It really does remediate the machine (services, WMI, registry, client reinstall), and it has no dry-run/Apply switch. `SupportsShouldProcess` does not make every operation preview-safe. Don't claim live CM, SQL, or webservice validation unless you actually ran it.

## Script architecture

The script is one `[CmdletBinding()]` script with `Begin` / `Process` / `End` blocks:

- **Begin**: sets `$Version`, `$PowerShellVersion`, and `$global:ScriptPath`. If neither `-Config` nor `-Webservice` is passed, it defaults `$Config` to `Config.xml` next to the script. Then it validates and loads the XML into `$Xml` and defines about 150 functions *inside the Begin block*. These functions share script-level state implicitly (`$Xml`, `$config`, `$PowerShellVersion`, `$global:ScriptPath`) rather than taking it as parameters.
- **Process**: runs the health checks in order: admin check, task-sequence check (exits 2), WMI, compliance-state refresh, client install/version, services, site code, cache, log size, provisioning mode, certificate, HW inventory, metering, DNS, BITS, and so on. Most checks only run when their `config.xml` toggle is on. Each `Test-*` function records its result on a shared `$Log` object from `New-LogObject`. It also sets flags such as `$reinstall` / `$restartCCMExec`, which later steps act on.
- **End**: writes the `LastRun` value to `HKLM:\Software\ConfigMgrClientHealth`. It then writes `$Log` to the local log file, the share log file, SQL (`Update-SQL`, only when `-Webservice` is not given), or the webservice (`Update-Webservice`).

Key function families:
- `Get-XMLConfig*`: thin accessors over `$Xml`. Each XML element or attribute usually has its own getter, and many fall back to a default (for example, the share defaults to `$global:ScriptPath`).
- `Test-*` / `Repair-*` / `Resolve-Client`: detection and remediation.
- `Out-LogFile`: CMTrace-format logging. Use it (and `Write-Verbose`) instead of ad hoc `Write-Host`.
- PS 5.1 compatibility: code branches on `$PowerShellVersion` to choose `Get-WmiObject` or `Get-CimInstance`.

**Coupled contracts:** `$Log` property names map to columns in `CreateDatabase.sql` and to the webservice payload. XML element and attribute names map to the `Get-XMLConfig*` getters. When you rename or add one of these, update every place it appears, or keep existing names unchanged.

## Test architecture

[Tests/ConfigMgrClientHealth.Tests.ps1](Tests/ConfigMgrClientHealth.Tests.ps1) **never dot-sources the script**, because doing so would run remediation. Instead, each test pulls the source of individual functions out of the script with a regex and `Invoke-Expression`s it:

```powershell
$pattern = "(?ms)^\s*Function\s+$([regex]::Escape($name))\s*\{.*?^\s*\}\s*(?=^\s*Function\s+|\z)"
```

Tests then set the implicit state the function expects (`$script:Xml`, `$script:config`, `$global:ScriptPath`, `$PowerShellVersion`) and `Mock` every external effect (`Get-CimInstance`, `Get-WmiObject`, `Get-Service`, `Stop-Service`/`Start-Service`, `Test-Path`, `Invoke-RestMethod`, …). If a function calls other script functions, extract those as well or mock them. Tests must not depend on the host OS. Because the regex keys on `Function Name {` at the start of a line followed by the next `Function`, keep that layout when editing functions.

## Rules specific to this repo

- Keep the XML-driven config contract; don't replace config values with hidden defaults. Keep the script self-contained, with no new shared modules.
- Match the existing style and use full cmdlet names. Avoid rewriting code that doesn't need to change.
- Don't add real hostnames, users, or share paths to examples or docs. Use placeholders.
- Don't log secrets, and don't add credential or silent-auth flows. SQL uses integrated auth.
- Keep [README.md](README.md) in sync when config elements, logging, or remediation behavior change.
- PRs: explain the reason for config or behavior changes, and list anything not validated or specific to an environment.
