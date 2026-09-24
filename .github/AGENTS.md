# AGENTS

Follow [copilot-instructions.md](copilot-instructions.md). It is the single source of repository guidance, including the rule never to run or dot-source the remediation script. This file only lists where things are.

## Navigation

- Implementation: [ConfigMgrClientHealth.ps1](../ConfigMgrClientHealth.ps1)
- Sample configuration: [config.xml](../config.xml)
- Database schema: [CreateDatabase.sql](../CreateDatabase.sql)
- Operator documentation: [README.md](../README.md)
- Tests: [Tests/ConfigMgrClientHealth.Tests.ps1](../Tests/ConfigMgrClientHealth.Tests.ps1)
- CI workflow: [workspace-tests.yml](workflows/workspace-tests.yml)
- Style rules: [instructions/](instructions/)
- Agents: [maintainer](agents/cm-client-health-maintainer.agent.md), [tests](agents/test-smith.agent.md), [review](agents/lint-smith.agent.md), and [documentation](agents/doc-writer.agent.md)
