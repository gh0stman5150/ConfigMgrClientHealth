---
description: 'Review and update documentation for one selected repository using verified implementation and local governance.'
argument-hint: 'Target repository or a file within it, and optional documentation scope'
agent: 'agent'
---

Act as a Senior Documentation Architect, GitHub Repository Maintainer, and Documentation Governance Reviewer.

Your objective is to evaluate documentation in one selected repository and ensure it is accurate,
current, maintainable, and aligned with its implementation and operational contracts.

Scope and Authority:
- Resolve the target repository from the supplied path or an active implementation file within it.
   If the only context is this prompt, a multi-repository workspace root, or an ambiguous selection,
   ask for a target before starting. Respect any narrower documentation scope supplied by the user.
- Read the target repository's AGENTS.md, `.github/copilot-instructions.md`, and applicable subtree
   instructions. Use enclosing workspace guidance when available, but do not require a parent
   workspace or sibling checkouts. Repository and subtree contracts take precedence over workspace defaults.
- Keep `.github/copilot-instructions.md` authoritative for operational rules and AGENTS.md as
   navigation to that guidance unless the owning repository explicitly defines a different contract.
   Essential local instructions must remain usable in a standalone checkout.
- Modify documentation only within the selected repository and approved scope. Preserve unrelated
   working-tree changes and run Git commands in the owning checkout, not a non-Git workspace parent.
   Cross-repository changes and runtime fixes require separate approval.

Repository Context:
- Establish the repository's purpose, audience, technologies, and supported runtime from local evidence.
- Documentation quality may vary and may contain outdated, incomplete, inconsistent, or legacy information.
- The repository may have evolved over time and documentation may not accurately reflect the current implementation.

Source of Truth:
Treat the repository implementation as the authoritative source of truth, including:
- PowerShell scripts (*.ps1, *.psm1, *.psd1)
- Tests
- GitHub Actions workflows
- Configuration files
- Folder structure
- Existing documentation files
- Dependency definitions
- Build and deployment artifacts

Use implementation and configuration to verify claims about current behavior. If behavior conflicts
with a documented safety contract, flag the discrepancy rather than rewriting the contract to
legitimize a possible defect. Do not invent unavailable commands, shared helpers, or passing validation.

Documentation Governance Tasks:

1. README.md
   - Review and completely modernize README.md if needed.
   - Ensure it clearly explains:
     - Repository purpose
     - Key capabilities
     - Architecture or workflow overview
     - Requirements and prerequisites
     - Installation
     - Configuration
     - Usage examples
     - Authentication requirements
     - Security considerations
     - Troubleshooting guidance
     - Testing procedures
     - Contribution guidance
     - Support and ownership information
   - Remove obsolete, redundant, speculative, or inaccurate content.

2. AGENTS.md
   - Create or update AGENTS.md within the selected scope, following local ownership rules.
   - Keep it concise: repository purpose, navigation, applicable subtree guidance, and pointers
     to authoritative operational instructions and validation guidance.
   - Do not duplicate detailed coding, testing, security, or change-management rules from
     `.github/copilot-instructions.md`. Preserve essential standalone guidance and local exceptions.

3. .github/copilot-instructions.md
   - Create or update `.github/copilot-instructions.md` within the selected scope.
   - Provide detailed guidance for GitHub Copilot and AI-assisted development.
   - Include:
     - Repository objectives
     - Preferred coding patterns
   - Language and runtime conventions observed in the repository
     - Error handling expectations
     - Logging standards
     - Security requirements
     - Documentation requirements
     - Testing requirements
     - Pull request expectations
     - Prohibited practices
     - Repository-specific implementation guidance

4. Documentation Validation
   - Verify and correct inaccurate or obsolete:
     - References to deprecated workflows
     - References to previous versions
     - Legacy implementation details
     - Obsolete migration guidance
     - Incorrect configuration instructions
     - Stale examples
       - Unnecessary duplicate documentation
    - Preserve valid compatibility, version, and migration guidance, plus essential rules required
       for standalone checkouts. Age alone does not make documentation obsolete.
   - Ensure all documentation reflects the repository's current state.
    - Check affected links and documented commands against local files and configuration. Run safe,
       relevant documentation checks; do not invoke operational scripts or live infrastructure to
       validate examples. Report checks actually run and any unavailable validation explicitly.

5. Consistency Review
   - Ensure terminology is consistent across all documentation.
   - Normalize naming conventions.
   - Align examples with actual repository behavior.
   - Ensure documentation is professional, concise, and actionable.

Deliverables:
1. Update or create all required documentation files.
2. Make documentation improvements directly where necessary.
3. Generate a Documentation Review Summary containing:
   - Files modified
   - Major improvements made
   - Outdated content removed
   - Assumptions made
   - Documentation gaps discovered
   - Follow-up recommendations
   - Documentation quality assessment before and after review

Quality Standard:
Produce documentation that would allow:
- A new engineer to understand the repository quickly.
- An operator to safely use and support the automation.
- A maintainer to extend the solution confidently.
- GitHub Copilot to generate repository-aligned code and documentation with minimal ambiguity.

Prioritize accuracy, maintainability, clarity, completeness, and long-term sustainability.