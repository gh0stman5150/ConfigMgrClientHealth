# AGENTS

This repository is a PowerShell-based Configuration Manager client health remediation tool. The implementation lives primarily in [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1), with configuration examples in [config.xml](../config.xml), database setup in [CreateDatabase.sql](../CreateDatabase.sql), and operational guidance in [README.md](../README.md).

## Repository purpose

- Validate Configuration Manager client health on Windows endpoints.
- Repair common misconfigurations and service issues.
- Log health data to SQL and optionally push results to the webservice.
- Use XML-driven configuration instead of hard-coded environment-specific logic.

## Navigation

- Primary implementation: [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1)
- Sample configuration: [config.xml](../config.xml)
- Database schema: [CreateDatabase.sql](../CreateDatabase.sql)
- Local operational guidance: [README.md](../README.md)
- Regression tests: [Tests/ConfigMgrClientHealth.Tests.ps1](../Tests/ConfigMgrClientHealth.Tests.ps1)
- CI workflow: [workspace-tests.yml](workflows/workspace-tests.yml)
- Agents: [maintainer](agents/cm-client-health-maintainer.agent.md), [tests](agents/test-smith.agent.md), [review](agents/lint-smith.agent.md), and [documentation](agents/doc-writer.agent.md)
- AI and repo-specific instructions: [copilot-instructions.md](copilot-instructions.md)

## Operational guidance

- Treat the script and configuration as the source of truth for current behavior.
- Keep changes scoped to this repository unless a broader workspace change is explicitly requested.
- Do not add runtime logic or documentation that contradicts the implemented XML schema, SQL schema, or service-based remediation behavior.
- Preserve environment-specific values as placeholders rather than copying production hostnames or share paths.
- Keep safety and remediation behavior aligned with the repository's runtime model: Windows local admin or SYSTEM, shares, SQL, and webservice integrations.

## Validation expectations

- Validate XML and PowerShell syntax; run focused Pester tests for behavior changes using the command in repository guidance. Never execute the full remediation entry point as a validation shortcut.
- Prefer focused checks over live endpoint changes when documentation-only work is being performed.
- Do not describe unrun live CM or SQL validation as passing.

For detailed repository-specific guidance, see [copilot-instructions.md](copilot-instructions.md).
