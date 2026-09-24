# ConfigMgr Client Health

ConfigMgr Client Health is a Windows PowerShell remediation workflow for Configuration Manager clients that are unhealthy, misconfigured, or not reporting properly. The script evaluates a target computer against Configuration Manager client expectations and repairs the most common client-side problems without requiring a full reimage.

## Repository purpose

This repository contains the core remediation script, a sample XML configuration, a database schema for storing health results, and the packaged webservice artifact used for centralized client data collection.

## Key capabilities

The current implementation in [ConfigMgrClientHealth.ps1](ConfigMgrClientHealth.ps1) validates and repairs the following conditions:

- Configuration Manager client installation state and site assignment
- Client version compliance against the configured minimum version
- Windows 11 modern-version detection, including 24H2 and 26H2-era client health checks
- Client provisioning mode and state message health
- WUA handler and client certificate state
- Log size and log history settings for the ConfigMgr client
- Cache size and orphaned cache cleanup
- WMI repair and service health checks
- Hardware inventory, software metering, DNS, and pending reboot remediation
- Windows Update and patch-level validation for known problematic builds
- SQL logging and optional webservice integrations for centralized reporting

## Repository layout

- [ConfigMgrClientHealth.ps1](ConfigMgrClientHealth.ps1): the production PowerShell entry point
- [config.xml](config.xml): sample XML configuration for a site and client-health profile
- [CreateDatabase.sql](CreateDatabase.sql): SQL database and schema creation script
- [Download](Download): packaged stable builds, including the webservice package

## Architecture and workflow

1. The script reads an XML configuration file and validates that it is well-formed.
2. It inspects local Windows state using CIM/WMI, registry values, services, and Configuration Manager APIs.
3. It compares that state to the policy in the XML file and records the result in a log object.
4. Depending on configuration, it updates a local file log, writes to SQL, and optionally posts results to a webservice.
5. It applies remediation actions such as service repair, registry changes, state resets, or client reinstall when enabled.

This is a single-script operational tool rather than a module-based PowerShell project.

## Requirements and prerequisites

### Runtime requirements

- Windows client or server OS with the Configuration Manager client installed or available for deployment
- PowerShell 5.1 or later on a supported Windows host
- Local administrator rights; running under the SYSTEM account is recommended for unattended remediation
- Access to the Configuration Manager source share used by the client package
- Access to any configured log share, SQL Server, or webservice endpoint

### Dependencies

- The XML configuration file must exist and be valid XML.
- The SQL path depends on a `ClientHealth` database created by [CreateDatabase.sql](CreateDatabase.sql).
- The webservice path is optional and used only when `-Webservice` is supplied.

## Installation

1. Download or clone this repository to the target management or packaging location.
2. Review and customize [config.xml](config.xml) for your environment.
3. Create the SQL database with [CreateDatabase.sql](CreateDatabase.sql) if you plan to write results to SQL.
4. Ensure the target endpoint can access the source share and file log destinations required by the configuration.
5. Run the script from an elevated PowerShell session.

## Configuration

The repository includes a sample configuration in [config.xml](config.xml). The file defines site metadata, client version expectations, source paths, logging, service rules, and remediation toggles.

Typical configuration elements include:

- `Client` settings for the target site code, source share, cache size, and log settings
- `ClientInstallProperty` values used when the client is reinstalled
- `Log` entries for file and SQL logging
- `Option` entries for feature toggles such as WMI repair, pending reboot handling, DNS checks, and cache cleanup
- `Service` definitions for required Windows services and states
- `Remediation` entries that enable or disable specific repair actions

Important: values in [config.xml](config.xml) are environment-specific and must be reviewed before use in production.

## Usage examples

Run the script with the default local configuration file:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ConfigMgrClientHealth.ps1
```

Run against a specific configuration file:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ConfigMgrClientHealth.ps1 -Config .\config.xml
```

Run with a centralized webservice:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ConfigMgrClientHealth.ps1 -Config .\config.xml -Webservice https://cm01.contoso.com/ConfigMgrClientHealth
```

Use `-Verbose` to capture execution details when troubleshooting:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\ConfigMgrClientHealth.ps1 -Config .\config.xml -Verbose
```

## Authentication and access requirements

The script uses the current Windows security context. For production use, run as a local administrator or SYSTEM account. The script does not prompt for SQL credentials; `CreateDatabase.sql` expects integrated authentication against the configured SQL Server.

The following access paths must be validated before use:

- source share for the Configuration Manager client installation files
- file share for log output
- SMB access to any remote configuration or update share
- SQL connectivity where database logging is enabled

## Security considerations

- Do not grant end users write access to the script or the configuration share.
- Protect the configuration XML and log paths from unauthorized modification.
- Review the source and log shares before enabling remediation actions.
- Keep the script and database updates in a controlled deployment process.
- Do not commit personal hostnames, domain names, or production share paths into shared examples.

## Troubleshooting guidance

Use the following checks when the script does not behave as expected:

- Confirm the XML file is valid and the path resolves correctly.
- Check whether the configured log share or local log path is writable.
- Validate SQL connectivity when `Log Name="SQL"` is enabled.
- Confirm the client source share contains the expected `ccmsetup.exe` payload.
- Review verbose output and the generated client health log for which remediation step failed.
- Verify local permissions and whether the script is running under a sufficiently privileged context.
- If the client needs to be installed or reinstalled but `ccmsetup.exe` on the client share can't be reached, the script logs the error, skips the remaining checks, records "Client installer not reachable." in `ClientInstalledReason`, writes the results to the configured logs, SQL, or webservice, and exits with code 1.
- The script waits at most 15 minutes for `ccmsetup.exe`, for each `wusa.exe` update install, and for removing task sequence client settings. If a ccmsetup uninstall is still running after 15 minutes, it skips the reinstall, records "Uninstall timed out.", and exits with code 1. An install that is still running is logged as a warning and left to finish on its own.
- If the log says "The health checks did not run" and the script exits with code 1, the launcher started `powershell.exe -File` with redirected standard input. Windows PowerShell 5.1 then skips the script's health checks. Start it without redirecting standard input.

The script writes log output using a CMTrace-style format and can fall back to a local `C:\ClientHealth` path depending on configuration.

Status messages shown on the console, including each check's result and any remediation (for example "DNS Check: OK", "Service BITS running: OK" or "ConfigMgr Client database corrupt. Reinstalling..."), are also written to the log files as they happen, so unattended runs keep them:

- to the local `ClientHealth.log` when `LocalLogFile="True"`
- to the share log when the `File` log is enabled and `Level="Full"`

These lines appear before the end-of-run summary block that starts with `<--- ConfigMgr Client Health Check starting --->`. With `Level="ClientInstall"`, the share log receives only the existing failure entries, not these status messages.

## Testing and validation

The repository includes a [Pester regression suite](Tests/ConfigMgrClientHealth.Tests.ps1) and a [Windows CI workflow](.github/workflows/workspace-tests.yml). From the repository root, run `Invoke-Pester -Path ./Tests -Output Detailed` using the Pester version configured by the workflow. Tests load isolated functions instead of executing the remediation entry point. Mocked tests do not verify live integrations. Additional validation includes:

- PowerShell parsing of the script entry point
- XML validation of the configuration
- Manual execution on an explicitly authorized non-production test host
- Review of local log output and SQL writes before wider rollout

## Contribution guidance

- Keep changes scoped to the script, schema, configuration examples, or operational documentation.
- Preserve compatibility with the existing XML-driven configuration design unless a broader change is explicitly required.
- Update documentation when behavior changes.
- Avoid hard-coded production hostnames, tenant identifiers, or deployment-specific secrets in examples.

## Support and ownership

This project is a script-based operational tool and the repository includes release assets in the [Download](Download) folder. This documentation reflects the current implementation in the codebase and should be treated as the local source of truth for how the project behaves today.

This software is provided "AS IS" with no warranties. Use at your own risk.
