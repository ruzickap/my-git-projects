# AI Agent Guidelines

## Overview

This document provides guidelines and best practices for AI agents working
on this repository. Follow these standards to ensure consistency, quality,
and maintainability across all contributions.

## Table of Contents

- [AI Agent Guidelines](#ai-agent-guidelines)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Markdown Files](#markdown-files)
    - [Linting and Formatting](#linting-and-formatting)
    - [Markdown Best Practices](#markdown-best-practices)
    - [Shell Scripts](#shell-scripts)
    - [JSON Files](#json-files)
    - [Terraform Files](#terraform-files)
    - [TypeScript/JavaScript Files](#typescriptjavascript-files)
    - [Link Checking](#link-checking)
  - [Security Scanning](#security-scanning)
  - [GitHub Actions](#github-actions)
  - [Version Control](#version-control)
    - [Commit Messages](#commit-messages)
      - [Format Rules](#format-rules)
      - [Commit Message Structure](#commit-message-structure)
        - [Example](#example)
    - [Branching](#branching)
    - [Pull Requests](#pull-requests)
  - [Quality \& Best Practices](#quality--best-practices)

## Markdown Files

### Linting and Formatting

- **Markdown compliance**: Ensure all Markdown files pass `rumdl` checks
- **Code blocks**: For `bash`/`shell` code blocks:
  - Verify they pass `shellcheck` validation
  - Format with `shfmt` for consistency
- Check if URL links are accessible using `lychee`

### Markdown Best Practices

- Use proper heading hierarchy (don't skip levels)
- Wrap lines at 72 characters for readability
- Use semantic HTML only when necessary
- Prefer code fences over inline code for multi-line examples
- Include language identifiers in code fences (e.g., `bash`, `json`)

### Shell Scripts

- **Linting**: All shell scripts must pass `shellcheck` validation
- **Formatting**: Format with `shfmt` using these settings:
  - `--case-indent`: Indent case statements
  - `--indent 2`: Use 2 spaces for indentation
  - `--space-redirects`: Add space before redirection operators
- **Excluded checks**: SC2317 (unreachable command warning) is excluded

**Code blocks in Markdown**: Shell code blocks (tagged as `bash`, `shell`,
or `sh`) are extracted and validated during CI.

### JSON Files

- **Linting**: Must pass `jsonlint` validation
- **Comments**: JSON files may include comments (supported via
  `--comments` flag)
- **Excluded files**: `.devcontainer/devcontainer.json` is excluded

### Terraform Files

- **Linting**: Must pass `tflint` checks
- **Security**: Must pass `checkov`, `kics`, and `trivy` security scans
- **Trivy severity**: Only HIGH and CRITICAL vulnerabilities fail the build
- **KICS severity**: Only HIGH severity issues fail the build

### TypeScript/JavaScript Files

- **Formatting**: Must be formatted with `prettier`
- **HTML whitespace**: Uses `--html-whitespace-sensitivity=ignore`

### Link Checking

- **Tool**: `lychee` validates all URLs in the repository
- **Valid status codes**: 200 (OK) and 429 (rate limited)
- **Caching**: Link results are cached; 403/429 responses are re-checked
- **Excluded URLs**:
  - Template variables (`%7B.*%7D`)
  - Shell variables (`\$`)
- **Excluded files**: `CHANGELOG.md`, `package-lock.json`
- **Private IPs**: All private IP addresses are excluded

## Security Scanning

Multiple security scanners run during CI:

- **Checkov**: IaC security scanner (quiet mode)
  - Skipped check: `CKV_GHA_7` (workflow_dispatch inputs)
- **DevSkim**: Security pattern scanner
  - Ignored rules: DS162092 (debug code), DS137138 (insecure URL)
  - Excluded files: `CHANGELOG.md`
- **KICS**: Security scanner (fails only on HIGH severity)
- **Trivy**: Vulnerability scanner (HIGH/CRITICAL only, ignores unfixed)

## GitHub Actions

- **Validation**: Each time you modify a GitHub Action workflow file or
  composite action, validate with `actionlint`
- **Permissions**: Use minimal permissions (prefer `read-all` or
  `permissions: read-all`)
- **Pin actions**: Always pin actions to full SHA commits, not tags

## Version Control

### Commit Messages

#### Format Rules

- **Conventional commit format**: Use standard types (`feat`, `fix`, `docs`,
  `chore`, `refactor`, `test`, `style`, `perf`, `ci`, `build`, `revert`)
- **Line limits**: Subject ≤ 72 characters, body lines ≤ 72 characters
- **Single blank line**: Between subject and body, between body paragraphs
- **Validation**: Commits are validated by `commit-check` action

#### Commit Message Structure

- **Subject line**:
  - Imperative mood (e.g., "add" not "added" or "adds")
  - Use lower case (except for proper nouns and abbreviations)
  - No period at the end
  - Maximum 72 characters
  - Format: `<type>: <description>`

- **Body** (optional but recommended for non-trivial changes):
  - Explain **what** changed and **why**
  - Wrap lines at 72 characters
  - Use Markdown formatting
  - Separate paragraphs with blank lines
  - Reference issues using keywords: `Fixes`, `Closes`, `Resolves`

##### Example

```markdown
feat: add automated dependency updates

- Implement Dependabot configuration
- Configure weekly security updates
- Add auto-merge for patch/minor updates

Resolves: #123
```

### Branching

- **When creating new branches**: Always follow the
  [Conventional Branch](https://conventional-branch.github.io/)
  specification with format: `<type>/<description>`

- **Supported branch types**:
  - `feature/` (or `feat/`): For new features
  - `bugfix/` (or `fix/`): For bug fixes
  - `hotfix/`: For urgent fixes
  - `release/`: For preparing releases (e.g., `release/v1.2.0`)
  - `chore/`: For non-code tasks (dependency updates, docs)

- **Naming guidelines**:
  - Use lowercase letters, numbers, and hyphens only
  - Keep branch names clear, concise, and descriptive
  - Include issue/ticket number when applicable:
    `feature/issue-123-add-login-page`
  - No consecutive, leading, or trailing hyphens
  - Use dots only in release versions: `release/v1.2.0`

### Pull Requests

- **Always create draft PR** - Create pull requests as drafts initially
- **Title format** - Must follow conventional commit format
  (validated by `semantic-pull-request` action)
- **Description** - Include clear explanation of changes and motivation
- **Link issues** - Reference related issues using keywords (Fixes, Closes,
  Resolves)

## Quality & Best Practices

- Pass pre-commit hooks
- Follow project coding standards
- Include tests for new functionality
- Update documentation for user-facing changes
- Make atomic, focused commits
- Explain reasoning behind changes
- Maintain consistent formatting
