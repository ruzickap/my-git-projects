# AI Agent Guidelines

## Project Overview

Infrastructure-as-code repository (`ruzickap/my-git-projects`) managing
Cloudflare, GitHub, Supabase, and UptimeRobot resources via OpenTofu.
Also contains GitHub Actions workflows, multi-gitter scripts, and repository
default templates distributed to ~40+ repos.

**Tech stack**: HCL (OpenTofu/Terraform), Bash, YAML, JSON5
**No application code or tests** -- quality is enforced through linting,
security scanning, and CI validation.

## Repository Structure

```text
opentofu/cloudflare-github/  # Main IaC module (Cloudflare, GitHub, etc.)
opentofu/aws/                # AWS IAM bootstrap module (apply first)
gh-repo-defaults/            # Default files synced to ~40+ repos
multi-gitter/                # Scripts for bulk repo updates
.github/workflows/           # CI: MegaLinter, OpenTofu plan/apply
```

## Build / Lint / Test Commands

### OpenTofu (run from `opentofu/cloudflare-github/`)

```bash
tofu init                             # Initialize providers and backend
tofu fmt -check -recursive            # Check HCL formatting
tofu validate                         # Validate configuration
tofu plan                             # Preview changes (requires secrets)
tofu apply                            # Apply changes (requires secrets)
```

OpenTofu `1.11.5` is pinned in `opentofu/cloudflare-github/mise.toml` (managed
by [mise](https://mise.jdx.dev/)).

### Pre-commit (run from repo root)

```bash
pre-commit run --all-files            # Run ALL hooks (full suite)
pre-commit run "hook-id" --all-files  # Run single hook
pre-commit run shellcheck --all-files # Lint shell scripts
pre-commit run shfmt --all-files      # Format shell scripts
pre-commit run actionlint-system --all-files
pre-commit run terraform_fmt --all-files
pre-commit run rumdl-fmt --all-files # Lint + format markdown
pre-commit run keep-sorted --all-files
```

Install: `pre-commit install && pre-commit install --hook-type commit-msg`

### Individual Linters

```bash
shellcheck script.sh                         # Lint shell script
shfmt --indent=2 --space-redirects script.sh # Format shell script
actionlint                                   # Validate GH Actions workflows
rumdl file.md                                # Lint markdown
lychee --cache .                             # Check URLs
tflint                                       # Lint Terraform/OpenTofu
checkov --quiet -d .                         # IaC security scan
trivy fs --severity HIGH,CRITICAL .          # Vulnerability scan
codespell                                    # Spell check (config: .codespellrc)
```

CI: MegaLinter (cupcake flavor) in `.github/workflows/mega-linter.yml`; OpenTofu
plan/apply in `.github/workflows/tofu-cloudflare-github.yml`.

## Code Style Guidelines

### HCL / OpenTofu

- **Naming**: `snake_case` for all resource names, variables, locals
- **Resource naming**: use `this` as the resource name with `for_each`
- **Data-driven pattern**: define resources as maps in `locals`, iterate with
  `for_each`; use `try()` for optional fields
- **Lifecycle**: use `prevent_destroy = true` on critical resources
- **Format**: `tofu fmt` (canonical HCL formatting); two-space indent; align
  `=` signs within blocks
- **Sorted blocks**: use `# keep-sorted` for alphabetical ordering; add
  `block=yes` for multi-line blocks and `newline_separated=yes` when blocks are
  separated by blank lines
- **Security annotations** (inline suppression):
  - `# kics-scan ignore-line`
  - `# checkov:skip=CKV_...`
  - `# trivy:ignore:avd-git-0001 <reason>`
  - `# codespell:ignore` (end-of-line, for false-positive words)

### Shell Scripts

- Shebang: `#!/usr/bin/env bash`; always `set -euo pipefail`
- UPPERCASE variables with braces: `${MY_VARIABLE}`
- Format: `shfmt --indent=2 --space-redirects`
- Lint: `shellcheck` (SC2317 excluded)
- Two-space indentation; use functions for reusable logic
- Redirect stderr for logging: `echo "msg" >&2`
- Validate dependencies early: `command -v tool > /dev/null || die "..."`

### YAML

- Start files with `---`; two-space indentation
- Lint: `yamllint` (relaxed profile, line-length disabled)
- Format: `prettier` (markdown excluded from prettier)
- Use `# keep-sorted` for sorted lists

### Markdown

- Lint: `rumdl` (not markdownlint); line-length applies to prose only (code
  blocks excluded via `.rumdl.toml`)
- Wrap at 80 characters; proper heading hierarchy
- Language identifiers required in code fences
- `CHANGELOG.md` is auto-generated -- excluded from all linting

### JSON / JSON5

- Lint JSON with `jsonlint --comments` (comments allowed)
- JSON5 used for Renovate config (`.github/renovate.json5`)
- Excluded from lint: `.devcontainer/devcontainer.json`

### GitHub Actions Workflows

- **Always validate with `actionlint`** after modifications
- Pin all actions to full SHA with version comment:
  `uses: actions/checkout@<full-sha> # v4.2.0`
- Set `permissions: read-all` at workflow level, override per-job with minimal
  permissions and inline comments explaining each
- Prefer `ubuntu-24.04-arm` runners
- Set explicit `timeout-minutes` on jobs
- Use `# keep-sorted` for env blocks

### Spell Checking

- `codespell` (pre-commit): config in `.codespellrc`; custom ignores for
  abbreviations like `aks`
- `typos` (optional): config in `_typos.toml`

## Security

- **Secrets**: passed as `TF_VAR_*` environment variables; never in code
- **Secrets in CI**: stored as GitHub repository secrets
- **Security scanners** (all in CI):
  Checkov (skip `CKV_GHA_7`), DevSkim (ignore DS162092, DS137138), KICS (HIGH
  only), Trivy (HIGH/CRITICAL, ignores unfixed), Gitleaks (pre-commit hook)

## Version Control

### Commit Messages

Conventional commits enforced by commitizen, gitlint, and commit-check.

- Format: `<type>: <description>` (lowercase, no period)
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `style`, `perf`,
  `ci`, `build`, `revert`
- Subject: imperative mood, max 72 characters
- Body: wrap at 72 chars, explain what/why, reference issues with `Fixes`,
  `Closes`, `Resolves`
- Direct commits to `main`/`master` blocked by pre-commit hook

### Branching

Conventional branch format: `<type>/<description>` -- `feature/`, `feat/`,
`bugfix/`, `fix/`, `hotfix/`, `release/`, `chore/`. Use lowercase, hyphens, no
consecutive/leading/trailing hyphens.

### Pull Requests

- Create as **draft**; title must follow conventional commit format
- Link related issues with keywords; CI must pass before merge

## Quality Checklist

- [ ] `pre-commit run --all-files` passes
- [ ] HCL formatted with `tofu fmt`
- [ ] Shell scripts pass `shellcheck` and `shfmt`
- [ ] GitHub Actions validated with `actionlint`; pinned to full SHA
- [ ] Markdown wrapped at 80 characters
- [ ] `# keep-sorted` blocks remain sorted
- [ ] No secrets or credentials in code; two-space indentation (no tabs)
