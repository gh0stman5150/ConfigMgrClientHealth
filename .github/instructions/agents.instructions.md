---
applyTo: '.github/agents/**/*.agent.md'
description: 'Agent design standards for the PowerShell Projects workspace'
---

# PowerShell Projects Workspace Agent Standards

This workspace contains multiple PowerShell repositories coordinated through WindowsAdmin.Core shared modules. Workspace-level agents coordinate across repos and enforce consistency. Repo-level agents handle domain-specific logic.

## 1. Agent Scope Requirements

1. Workspace-level agents must coordinate across repos, not duplicate repo-specific logic.
2. Repo-level agents must handle domain-specific operations and safety rules.
3. Agents must have a narrowly defined responsibility.
4. Agents must not combine planning, implementation, and review in one role.
5. Agents must support non-interactive automation.

## 2. Workspace vs Repo Level

### Workspace-Level Agents (this directory)

1. Focus on cross-repo coordination, duplication detection, and WindowsAdmin.Core consolidation.
2. Use the canonical workspace inventory names when enumerating scope: AD_and_Policy, Endpoint-Management, Modern_PowerShell_ISEv2, NetworkShare-Permissions, SharePoint-Management, Tests, Tools, and WindowsAdmin.Core.
3. Must NOT contain repo-specific safety invariants (those belong in each repo).
4. Must defer to each repo's local copilot-instructions.md for domain rules.
5. Generic agent-template guidance belongs in the workspace `.github/agents.md`; repo-local files should keep only repo-specific deltas instead of duplicating the shared template.

### Repo-Level Agents

1. Focus on domain-specific operations and safety.
2. Must reference the correct domain (not copy-pasted from another repo).
3. May import and call WindowsAdmin.Core shared modules.
4. Must define domain-specific safety invariants.

## 3. Universal Safety Requirements

All agents at both levels must:

1. Preserve the owning entry point's actual defaults; do not assume every script is report-only.
2. Preserve supported Apply/WhatIf/DryRun semantics; do not invent parameters for existing scripts.
3. Preserve structured result objects and not rely on Write-Host.
4. Support WhatIf where applicable.
5. Never introduce interactive prompts in remote or automated paths.
6. Use Set-StrictMode -Version Latest and $ErrorActionPreference = 'Stop'.

## 4. Shared Module Awareness

Agents must:

1. Check WindowsAdmin.Core for existing shared functions before writing new logic.
2. Propose consolidation when duplicate patterns are found across repos.
3. Ensure shared modules have their own Pester tests.
4. Update consuming repos when shared module signatures change.

## 5. Tool Configuration Rules

1. Use the principle of least privilege.
2. Only include execute if command execution is explicitly required.
3. Do not enable agent tool unless orchestration is required.
4. If sub-agents need edit or execute, the orchestrator must include those tools.

## 6. Approved Agent Roles

### 6.1 Orchestrator Agent

Purpose:
1. Coordinate across repos.
2. Identify duplication and consolidation opportunities.
3. Enforce consistency.
4. Delegate to specialist agents.

Recommended tools: read, search, edit, agent, todo

### 6.2 Implementation Agent

Purpose:
1. Modify PowerShell modules or scripts.
2. Create or update shared modules in WindowsAdmin.Core.
3. Preserve structured outputs.
4. Update Pester tests when logic changes.

Recommended tools: read, search, edit, execute, todo

### 6.3 Test Specialist Agent

Purpose:
1. Write or update Pester tests.
2. Validate repo-specific safety invariants.
3. Test shared module integration.

Recommended tools: read, search, edit, execute, todo

### 6.4 Cleanup Agent

Purpose:
1. Remove duplication across repos.
2. Consolidate shared logic into WindowsAdmin.Core.
3. Remove stale code and documentation.

Recommended tools: read, search, edit, execute, todo

### 6.5 Documentation Agent

Purpose:
1. Standardize documentation across repos.
2. Add comment-based help to shared and repo-specific modules.
3. Never modify executable logic.

Recommended tools: read, search, edit, todo

### 6.6 Structure Agent

Purpose:
1. Scaffold and validate .github/ structures across repos.
2. Detect cross-repo inconsistencies.
3. Harmonize agent and instruction conventions.

Recommended tools: read, search, edit, todo

## 7. Orchestration Guidelines

If using handoffs:

1. Limit workflows to logical transitions such as Survey to Plan to Implement to Validate.
2. Do not create excessive sequential chains.
3. Ensure each step respects repo-specific safety invariants.
4. Workspace orchestrator should delegate domain work to repo-level agents where possible.
5. Use only built-in handoff targets or validated lowercase file-stem ids for custom agents; do not mix display names and ids in handoff metadata.

## 8. Output Standards

Agents must:

1. Return structured summaries.
2. Clearly list files created or modified, grouped by repo.
3. Identify risk areas per repo.
4. Identify required test updates.
5. Avoid conversational filler.

## 9. Testing Requirements

If an agent modifies logic:

1. It must also update Pester tests in the affected repo.
2. If shared module logic changed, tests in WindowsAdmin.Core must be updated.
3. It must verify consuming repos still pass their tests.

## 10. Model Selection Guidance

1. Use a stronger reasoning model for orchestrator and implementation agents.
2. Test and documentation agents may use moderate reasoning models.
3. Do not omit model selection for complex agents.

## 11. Prohibited Behaviors

Agents must not:

1. Contain repo-specific safety invariants at the workspace level.
2. Copy-paste another repo's domain rules into a different repo's agents.
3. Convert report-only mode into implicit Apply.
4. Add interactive prompts in remote or automated execution.
5. Duplicate logic that exists in WindowsAdmin.Core.
