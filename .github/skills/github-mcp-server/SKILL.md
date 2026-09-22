---
name: github-mcp-server
description: Configure and review GitHub MCP Server access for GitHub Copilot cloud agent and code review. Use when defining repository MCP servers, GitHub MCP tool access, scoped authentication, read-only access, tool allowlists, or MCP validation.
---

# GitHub MCP Server

Use this reference when configuring the built-in GitHub MCP server or reviewing repository MCP access for GitHub Copilot. Repository policy and the currently available GitHub Copilot configuration surface take precedence.

# Current Source Policy

- Consult [Configure MCP servers for your repository](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/extend-coding-agent-with-mcp) before making version-sensitive configuration claims.
- This document summarizes the official guidance retrieved on 2026-09-15. It is not a generated tool inventory and does not guarantee current availability.
- State when current documentation cannot be retrieved. Do not invent server configuration keys, tool names, authentication mechanisms, CLI commands, or compatibility claims.

# Configuration Principles

- Repository MCP configuration is JSON entered in the repository's GitHub Copilot MCP settings.
- The configuration uses an `mcpServers` object. Each server has a type and connection-specific settings.
- Copilot cloud agent and Copilot code review support MCP tools, but not MCP resources or prompts.
- The built-in GitHub MCP server and Playwright MCP server are enabled by default. The built-in GitHub server uses a specially scoped read-only token for the current repository by default.
- Select the smallest appropriate set of tools. GitHub recommends allowlisting specific read-only tools because agents can use configured tools autonomously.
- Treat broader access, write tools, external repositories, and custom authentication as explicit security decisions requiring the repository owner's authorization.

# Secrets and Authentication

- Do not place tokens, keys, or private-key material in configuration, source, examples, logs, or issue content.
- Use GitHub Agents secrets or variables whose names begin with `COPILOT_MCP_` when the MCP configuration requires secret or variable substitution.
- Prefer fine-grained, least-privilege credentials with the smallest necessary repository scope.
- For GitHub MCP access beyond the default read-only current-repository scope, require explicit authorization and review the chosen personal access token or GitHub App permissions.

# Review Checklist

- Is the server necessary for the requested workflow?
- Is each enabled tool explicitly justified, and are read-only tools preferred?
- Are write access, cross-repository access, and external network access explicitly approved?
- Are all secrets referenced through the required `COPILOT_MCP_` mechanism rather than embedded values?
- Does the configuration use valid JSON and the current official schema?
- Has the repository owner validated server startup and observed the intended tool list in the Copilot session logs?

# Validation

Validate the JSON in the GitHub repository's **Settings** > **Copilot** > **MCP servers** interface. Then validate with the intended Copilot cloud-agent or code-review workflow and inspect its session logs for server startup and invoked tools.

Do not report validation as successful unless it was actually performed.

# Reference

- [Configure MCP servers for your repository](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/extend-coding-agent-with-mcp), GitHub Docs, accessed 2026-09-15.
