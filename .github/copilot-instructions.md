# ConfigMgrClientHealth repository guidance

This repository implements a Windows-only remediation workflow for Configuration Manager client health. The authoritative code path is [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1), and the runtime contract is driven by [config.xml](../config.xml).

## Repository objective

Keep end-user devices compliant with Configuration Manager client health expectations by automatically checking for and correcting common client-side issues. The script intentionally runs as a local operational tool, not as a generic cross-platform automation framework.

## Key runtime model

- The tool is executed from a PowerShell session on the managed Windows endpoint.
- It is designed to run with local administrator privileges and is recommended to run under the SYSTEM context for unattended remediation.
- It reads XML-defined policy, checks local system state, and then applies remediation when enabled.
- It can write structured results to local file logs, SQL, and a webservice endpoint.

## Preferred coding patterns

- Prefer explicit parameter validation and plain PowerShell objects over indirect or hidden state.
- Keep functions small and focused on a single validation or remediation action.
- Use `Write-Verbose` for execution diagnostics; avoid `Write-Host` for structured data output.
- Preserve compatibility with the existing XML configuration contract unless a deliberate change is part of a broader repo revision.
- Use `SupportsShouldProcess` semantics where the script already expects preview-safe execution patterns.

## PowerShell conventions

- Prefer full cmdlet names over aliases.
- Keep the script self-contained; do not introduce workspace-wide shared modules unless the repo is intentionally refactored.
- Match the established style of the existing script and avoid gratuitous rewrites.
- Preserve object property names and XML element names when changing implementation because downstream SQL and logging code depend on them.

## Error handling and logging standards

- Fail gracefully with actionable messages when XML, share, or SQL access is invalid.
- Log operational outcomes with the repo's CMTrace-style format rather than ad hoc console output.
- Do not emit secrets, credentials, or private network details in logs.
- Treat missing file share access or SQL connectivity as environment/configuration problems, not as success conditions.

## Security requirements

- Only run on approved Windows endpoints and approved configuration packages.
- Protect configuration, log paths, and source share access to the least privilege necessary.
- Do not commit production hostnames, user names, or share paths into documentation examples.
- Do not add undocumented credential flows or silent authentication logic.

## Documentation requirements

- Keep [README.md](../README.md) aligned with implementation, not stale release notes.
- Update repository docs when configuration elements, log behavior, or remediation steps change.
- Link to authoritative local files instead of copying environment-specific operational guidance across docs.

## Testing and validation

The checked-in [Pester suite](../Tests/ConfigMgrClientHealth.Tests.ps1) runs through [CI](workflows/workspace-tests.yml). From the repository root, run `Invoke-Pester -Path ./Tests -Output Detailed` with the Pester version configured by that workflow. Record the actual runtime version and results. Additional validation should include:

- PowerShell parse validation for [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1)
- XML validation for [config.xml](../config.xml)
- Manual execution only in an explicitly authorized non-production environment
- Review of log and SQL output when the relevant features are enabled

Unit tests must load isolated functions and mock external effects; never execute or dot-source the full remediation entry point for test setup. The script has no Apply switch, and SupportsShouldProcess does not establish that every operation is preview-safe. Preserve XML-controlled remediation defaults. Do not claim live CM, SQL, or webservice validation without actually running it.

## Pull request expectations

- Keep pull requests scoped to the repo and the documented issue.
- Include the rationale for config or behavior changes.
- Note any unvalidated or environment-specific behavior in the PR description.
- Preserve compatibility with the current XML-driven architecture and SQL schema.

## Prohibited practices

- Do not hard-code server names or share paths into default example files.
- Do not replace the XML-driven config contract with undocumented defaults.
- Do not claim support for platforms or workflows the repo does not implement.
- Do not write secrets to the log or configuration files.
- Do not invent shared modules or helpers that are absent from this repository.

## Scope for agent work

- Prefer targeted changes in [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1), [config.xml](../config.xml), [CreateDatabase.sql](../CreateDatabase.sql), and repository docs.
- Preserve local file, SQL, and webservice behavior unless the task explicitly requires modifying that contract.
- Keep operational changes aligned with the established Configuration Manager client remediation model.

This guidance is intentionally local to this repository so a standalone checkout remains usable without workspace-wide assumptions.

