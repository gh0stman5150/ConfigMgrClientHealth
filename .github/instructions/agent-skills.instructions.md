# PowerShell Projects Workspace Skill Constraints

These rules apply when creating skills at the workspace level across the PowerShell Projects workspace.

## 1. Scope of Workspace-Level Skills

Workspace-level skills must support cross-repo or generic categories:

1. Code refactoring and cleanup patterns.
2. Pester test scaffolding and shared test helpers.
3. Module scaffolding and Copilot structure templates.
4. Code interpretation and quasi-code translation.
5. Cross-repo duplication detection.
6. WindowsAdmin.Core shared module generation.

Repo-specific skills (e.g., permission profiles, SID diagnostics, GPO generation) belong in each repo's own `.github/skills/` directory.

## 2. Universal Safety Awareness

All skills must respect:

1. Report-only as default behavior.
2. Apply requires explicit authorization.
3. No interactive prompts in automated paths.
4. Structured output objects required.
5. No credential embedding.

Skills must not weaken any repo-specific safety invariant. Defer domain-specific enforcement to each repo's own skill constraints.

## 3. Script Bundling Rules

When bundling scripts inside skills:

1. Prefer pwsh for Windows automation tasks.
2. Scripts must support a -WhatIf equivalent where applicable.
3. Scripts must not embed credentials.
4. Scripts must include structured output objects.
5. Scripts must reference WindowsAdmin.Core shared modules where available instead of duplicating logic.

## 4. Commit and Change Control

Skills that generate commit messages must follow this format:

First line:
fix: <short summary>

Body must include:
1. Context
2. Changes
3. Repos affected
4. Tests

Skills must not generate commits that:
1. Weaken repo-specific safety invariants.
2. Introduce duplication of WindowsAdmin.Core logic.
3. Mix changes across unrelated repos in a single commit.

## 5. Progressive Loading Discipline

Skill descriptions must clearly state:

1. What the skill does.
2. When to use it.
3. Keywords relevant to the skill's domain such as:
   PowerShell, Pester, refactor, scaffold, shared module,
   WindowsAdmin.Core, cross-repo, consolidation, cleanup.

If relevant keywords are absent, the skill may not activate when needed.

## 6. Shared Module Awareness

Skills that generate or modify PowerShell code must:

1. Check WindowsAdmin.Core for existing shared functions before creating new logic.
2. Propose consolidation when duplicate patterns are found.
3. Include import statements for WindowsAdmin.Core modules where applicable.

## 7. Refusal Conditions for Skills

Skills must refuse execution if the request attempts to:

1. Bypass any repo-specific safety invariant.
2. Convert report-only behavior into implicit Apply.
3. Duplicate logic that already exists in WindowsAdmin.Core.
4. Embed credentials or secrets.