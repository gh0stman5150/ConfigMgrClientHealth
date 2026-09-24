---
description: 'Audit workspace and repository efficiency audit/optimization.'
argument-hint: 'Multi-repository workspace root and repository'
agent: 'agent'
---

## Efficiency Audit

You are a senior software architect and performance optimization specialist.

Objective:
Conduct a comprehensive assessment of this repository and identify areas that contribute to excessive AI token consumption, unnecessary processing overhead, code inefficiencies, and maintainability issues.

Analysis Requirements:

1. Repository Structure
   - Review the overall architecture and folder organization.
   - Identify duplicated functionality, redundant files, unused assets, and unnecessarily large modules.
   - Highlight areas that increase context size when analyzed by AI coding assistants.

2. Token Consumption Analysis
   - Identify files, functions, classes, configuration files, prompts, documentation, and generated artifacts that consume excessive context window space.
   - Estimate relative impact (High, Medium, Low) for each finding.
   - Explain why each item is expensive from a token and maintainability perspective.

3. Code Quality Review
   - Identify:
     - Duplicate code
     - Dead code
     - Unused imports and dependencies
     - Excessive comments
     - Large functions
     - Deep nesting
     - Repeated business logic
     - Monolithic classes
   - Recommend refactoring opportunities.

4. AI Optimization Review
   - Evaluate the repository specifically for GitHub Copilot and LLM-assisted development efficiency.
   - Identify opportunities to:
     - Reduce context size
     - Modularize large files
     - Improve code discoverability
     - Reduce prompt complexity
     - Improve naming conventions
     - Reduce duplicated documentation

5. Dependency Analysis
   - Identify unused, outdated, duplicate, or overlapping libraries.
   - Recommend consolidations where appropriate.

6. Documentation Review
   - Evaluate README files, architecture documents, prompts, and markdown content.
   - Identify verbose sections that can be condensed.
   - Recommend restructuring to improve retrieval efficiency.

7. Configuration Review
   - Review build, deployment, CI/CD, and configuration files.
   - Identify unnecessary complexity and opportunities to simplify.

Output Format:

Provide results in the following structure:

# Executive Summary

## Overall Repository Health Score

- Score: X/10
- Key Concerns
- Quick Wins

## High-Impact Token Reduction Opportunities

| Area | Impact | Estimated Token Savings | Recommendation |
|--------|--------|--------|--------|

## Detailed Findings

### Finding 1

- Location:
- Issue:
- Impact:
- Recommendation:
- Example Refactor:

### Finding 2

...

## Prioritized Remediation Plan

### Immediate Actions (Highest ROI)

1.
2.
3.

### Short-Term Improvements

1.
2.
3.

### Long-Term Architectural Improvements

1.
2.
3.

## Expected Benefits

- Reduced repository size
- Improved GitHub Copilot performance
- Lower context requirements
- Better maintainability
- Faster onboarding
- Reduced technical debt

Focus on practical recommendations that provide the greatest reduction in token usage and developer effort while minimizing implementation risk.
