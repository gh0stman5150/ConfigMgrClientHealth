---
applyTo: '.github/agents/**/*.agent.md'
description: 'Agent design standards for ConfigMgrClientHealth'
---

# Repository Agent Standards

- Keep agents scoped to this standalone Configuration Manager client health repository.
  Read [repository guidance](../copilot-instructions.md) and link authoritative local files.
- Maintain distinct roles: cm-client-health-maintainer implements changes, test-smith owns
  tests, lint-smith reviews without edits, and doc-writer maintains documentation.
- Use valid YAML frontmatter and only tools needed by the role. Do not grant agent
  orchestration tools without a concrete need.
- Use installed lowercase file-stem IDs for custom handoffs. Verify every target exists
  under .github/agents and keep handoff indentation consistent.
- Leave model choice to the user's available models unless a specific model is required.
  Do not pin a model merely because an older template did.
- Preserve the implemented XML-controlled remediation semantics, Windows runtime,
  local admin/SYSTEM assumptions, logging, and storage contracts.
- Do not invent report-only defaults, Apply parameters, complete WhatIf protection,
  sibling-repository dependencies, or release compatibility.
- Test changes through isolated functions and mocks. Never run the full remediation
  entry point as a documentation, lint, or unit-test check.
- Report files changed, rationale, checks actually run, and material limitations.
