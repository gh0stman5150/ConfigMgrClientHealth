---
description: 'Audit workspace and repository AGENTS.md .'
argument-hint: 'Workspace root and repository'
agent: 'agent'
---

Act as a Senior Platform Engineer responsible for AI-agent tooling
consistency across a multi-repository workspace.

Your objective is to audit this workspace and establish a correct
`AGENTS.md` hierarchy: one workspace-level file plus one file per repository,
each containing only what belongs at its level, avoiding unnecessary duplication
while preserving essential standalone repository contracts.

## Ground rules

- Resolve the supplied multi-repository workspace root and any requested repository subset.
  If only a standalone repository is open and no workspace target is supplied, ask for
  the intended workspace scope; do not create a parent workspace hierarchy implicitly.
- Read workspace and owning repository guidance before editing. Preserve unrelated changes
  and run Git commands in each owning checkout; the workspace parent may not be a Git checkout.
- `AGENTS.md` discovery and inheritance depend on the consuming agent. Do not assume a
  universal nearest-file-only loading model. Follow applicable agent instructions and the
  repository's declared authority; repository and subtree contracts take precedence over
  generic workspace defaults.
- In this workspace, `.github/copilot-instructions.md` owns operational rules and AGENTS.md
  provides navigation. Preserve that division unless an owning repository explicitly defines
  a different contract. Do not migrate authority merely to favor a file convention.
- Keep essential repository contracts in the checkout so they remain usable without the
  parent workspace. Workspace guidance must not be the sole source of required local rules.
- Target length: keep every individual `AGENTS.md` file (workspace and
  per-repo) under roughly 300 lines. If a repo-level file would need to
  exceed that to stay useful, split further with nested `AGENTS.md` files
  inside that repo's subprojects rather than growing the single file.
- Do not invent conventions the workspace doesn't already have. Infer rules
  from what the repositories actually do (build tooling, test runners,
  directory structure, existing lint/CI config, existing instruction files
  such as `.github/copilot-instructions.md`, `CONTRIBUTING.md`, or
  per-repo `AGENTS.md` files already present). If something is ambiguous or
  contradicted across repos, flag it instead of guessing.

## Step 1: Inventory the workspace

1. List every repository in the workspace and, for each, note:
   - primary language(s)/runtime(s) and package manager,
   - build, lint, and test commands,
   - whether it already has an `AGENTS.md`, `.github/copilot-instructions.md`,
     `CLAUDE.md`, `.cursorrules`, or equivalent agent-instruction file,
   - any safety-critical or destructive operations it performs (data
     mutation, filesystem changes, deployments, external API calls) that an
     agent should be cautious around.
2. Identify what, if anything, is genuinely shared across *all* repositories
   in the workspace — not "true of most repos" but true of the workspace as
   a whole. Typical candidates: a shared monorepo build system, a shared
   commit-message or branch-naming convention, a shared review/PR process,
   how the repos relate to or depend on one another, workspace-wide
   prohibited practices (e.g., "never commit secrets," "never push directly
   to main across any repo here").
3. Identify what is repository-specific and must not be promoted to the
   workspace level: language conventions, per-repo test commands, per-repo
   safety invariants, per-repo directory maps, per-repo prohibited
   practices that don't apply elsewhere.

If a rule could plausibly belong in either place, put it at the repo level.
Over-scoping a repo-specific rule to the workspace file risks applying it to
other repositories where it is wrong or irrelevant.

## Step 2: Write or update the workspace-level `AGENTS.md`

Place this at the root of the workspace (the folder that contains the
repositories, not inside any one of them). Keep it short. It should answer,
for an agent that hasn't opened any individual repo yet:

- What is this workspace, and how do the repositories in it relate to each
  other (independent projects vs. a coordinated system)?
- Where is each repository, in one line, with a pointer to that repo's own
  `AGENTS.md` for specifics.
- Any workspace-wide conventions identified in Step 1.2 — commit/PR
  conventions, secrets handling, cross-repo dependency rules.
- Any workspace-wide prohibited practices.
- Nothing else. Do not restate any repo's build/test commands, language
  conventions, or repo-specific safety invariants here — those belong in
  that repo's own file, and duplicating them risks the two copies drifting
  out of sync.

## Step 3: Write or update each repository's `AGENTS.md`

For each repository identified in Step 1 that doesn't already have an
adequate one:

- Cover the following topics only where relevant. In AGENTS.md, provide concise
  navigation to the owning operational instructions for detailed rules and commands;
  update those instructions where needed instead of duplicating their contents.
  Do not invent content to fill a section:
  - **Purpose**: what the repo does, in a few sentences.
  - **Repository layout**: a directory map with one line per major path
    explaining its responsibility.
  - **Non-negotiable invariants**: behavior that must never change without
    explicit review — especially anything destructive, security-sensitive,
    or safety-critical (data mutation, deployments, auth, payments,
    filesystem or infra changes). If the repo has no such behavior, omit
    this section rather than padding it.
  - **Coding conventions**: patterns actually observed in the codebase
    (naming, error handling, structuring), not generic style-guide
    boilerplate the repo doesn't follow.
  - **Change workflow**: the expected sequence for making a change (tests
    to update, docs to update, review steps) if the repo has one worth
    stating.
  - **Validation commands**: exact, copy-pasteable build/lint/test commands
    with real flags — not "run the tests."
  - **Prohibited practices**: things an agent would otherwise plausibly do
    that are wrong for this specific repo.
  - **Known gaps / follow-ups**: open issues worth flagging to whoever
    touches this code next, if any exist.
- Avoid unnecessary repetition of workspace guidance, but preserve essential rules
  in the repository's own operational instructions for standalone use. Do not make
  required local guidance depend on a link outside the checkout.
- If the repo already has a `.github/copilot-instructions.md` or similar,
  preserve its declared authority and link to it from AGENTS.md. Do not consolidate
  operational rules into AGENTS.md or maintain parallel copies merely to keep both
  files populated. If ownership is ambiguous, report it before changing authority.
- If the repo is itself large enough that one file would exceed ~300 lines
  or would mix unrelated subproject conventions (e.g., a repo with separate
  frontend/backend/infra directories with different toolchains), add nested
  `AGENTS.md` files inside those subdirectories instead of inflating the
  repo-root file.

## Step 4: Verify ownership, necessary duplication, and consistency

1. Diff the content categories across the workspace file and every
   repo-level file. Flag any rule that appears in more than one file.
2. Remove unnecessary duplicates according to the declared ownership. Preserve
  essential local contracts even when a workspace-wide rule also states them;
  explain necessary duplication for standalone use in the review summary.
3. Confirm no repo-level file contradicts the workspace-level file. If one
   repo genuinely needs to override a workspace-wide rule, say so explicitly
   in that repo's file rather than leaving an unexplained conflict for the
   agent to guess about.
4. Confirm every repository referenced in the workspace-level file actually
   has the `AGENTS.md` it points to, and that the path is correct.
5. Verify that each repository's essential guidance and local links remain usable
  without the parent workspace. Report checks performed and unresolved gaps; do
  not claim validation for repositories outside the approved audit scope.

## Deliverables

1. The new or updated workspace-level `AGENTS.md`.
2. The new or updated `AGENTS.md` for each repository that needed one.
3. A short summary listing:
   - which repositories got a new file vs. an updated one,
   - what content was moved from a repo-level file up to the workspace
     level (or the reverse), and why,
   - any existing instruction files (`.github/copilot-instructions.md`,
    etc.) whose authority was preserved or clarified, and necessary duplication
    retained for standalone use,
   - any workspace-wide convention you inferred but could not confirm
     (call these out explicitly rather than asserting them as fact),
   - any repository you could not fully audit and why.
