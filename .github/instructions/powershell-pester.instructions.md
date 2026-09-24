---
applyTo: '**/*.Tests.ps1'
description: 'Pester regression testing standards for ConfigMgrClientHealth'
---

# ConfigMgr Client Health Pester Standards

Follow [repository guidance](../copilot-instructions.md) and
[PowerShell conventions](powershell.instructions.md). The filename is retained for existing
links; use the Pester version configured in [CI](../workflows/workspace-tests.yml).

## Structure and isolation

- Keep tests under Tests with the *.Tests.ps1 suffix.
- Use Describe for the function, Context for scenarios, and It for meaningful behavior.
- Load isolated functions and fixtures in BeforeAll or BeforeEach, following
  [the existing suite](../../Tests/ConfigMgrClientHealth.Tests.ps1).
- Never execute or dot-source the full production entry point to load functions.
- Restore global/script state changed by fixtures. Use TestDrive for temporary file tests.
- Mock CIM/WMI, services, registry writes, processes, network access, SQL, webservice
  requests, and reboot operations. Pair Should -Invoke assertions with mocks.

## Coverage

Cover the changed behavior and relevant failure paths: XML values and defaults, OS
classification, client health checks, remediation gates, logging/result properties,
and unavailable external resources. Assertions must match the implemented contract.
There is no Apply parameter or guaranteed report-only default.

Prefer behavior assertions to source-text checks. Do not delete or skip regression
tests to conceal failures. Keep live integration checks separate from mocked unit tests.

## Execution

From the repository root, run Invoke-Pester -Path ./Tests -Output Detailed.
Report the actual PowerShell/Pester versions, pass/fail/skip counts, and any unrun checks.
A passing mocked suite does not prove live Configuration Manager or SQL behavior.
