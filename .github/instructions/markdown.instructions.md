---
description: 'Repository documentation accuracy and maintenance standards'
applyTo: '**/*.md'
---

# Repository Markdown Standards

- Write operational repository documentation, not blog posts. Add frontmatter only when
  the file type requires it; do not invent author, publishing, image or category metadata.
- Treat code, manifests, workflows and configuration as the source of truth. Separate
  implemented behavior from proposed standards and unverified assumptions.
- Keep README usage, Copilot constraints and AGENTS routing complementary. Link shared
  guidance instead of copying templates, version catalogs or setup snippets across files.
- Use clear headings, readable lines, fenced examples and valid relative links. State the
  example's working directory, inputs, authentication and whether it performs real changes.
- Verify local paths, public parameters, exports, preview behavior and prerequisites.
  Preserve legitimate compatibility notes while removing inaccurate retirement claims.
- Document only validation actually performed. Never call a mocked test a live deployment
  test or label unmeasured performance and unavailable platforms as verified.
- Update affected docs with behavior changes. Record gaps and follow-ups without changing
  runtime semantics during a documentation-only task. Keep secrets and real data out of examples.
