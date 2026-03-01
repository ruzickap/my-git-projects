# AI Agent Guidelines

## Project Overview

Infrastructure-as-code repository (`ruzickap/my-git-projects`) managing
Cloudflare, GitHub, Supabase, and UptimeRobot resources via OpenTofu.
Also contains GitHub Actions workflows, multi-gitter scripts, and
repository default templates distributed to ~40+ repos.

**Tech stack**: HCL (OpenTofu/Terraform), Bash, YAML, JSON5
**No application code or tests** -- quality is enforced through linting,
security scanning, and CI validation.

## Build / Lint / Test Commands

### OpenTofu (run from `opentofu/cloudflare-github/`)

```bash
tofu init                             # Initialize providers and backend
tofu fmt -check -recursive            # Check HCL formatting
tofu validate                         # Validate configuration
tofu plan                             # Preview changes (requires secrets)
tofu apply                            # Apply changes (requires secrets)
```

OpenTofu version is pinned to `1.11.5` in `opentofu/cloudflare-github/mise.toml`.

### Pre-commit (run from repo root)

```bash
pre-commit run --all-files            # Run all hooks
pre-commit run shellcheck --all-files # Single linter example
pre-commit run shfmt --all-files
pre-commit run actionlint-system --all-files
pre-commit run terraform_fmt --all-files
```

Install: `pre-commit install && pre-commit install --hook-type commit-msg`

### Individual Linters

```bash
shellcheck script.sh                # Lint shell script
shfmt -ci -i 2 -sr script.sh        # Format shell script
actionlint                          # Validate GH Actions workflows
rumdl file.md                       # Lint markdown
lychee --cache .                    # Check URLs
tflint                              # Lint Terraform
checkov --quiet -d .                # IaC security scan
trivy fs --severity HIGH,CRITICAL . # Vulnerability scan
```

CI: MegaLinter (cupcake flavor) in `.github/workflows/mega-linter.yml`;
OpenTofu plan/apply in `.github/workflows/tofu-cloudflare-github.yml`.

## Code Style Guidelines

### HCL / OpenTofu Files

- Use `snake_case` for all resource names, variables, and locals
- Use `this` as the resource name when using `for_each`
- Use `try()` for optional fields in `for_each` maps
- Use `prevent_destroy = true` on critical resources
- Use `# keep-sorted` to maintain alphabetical ordering in blocks (providers,
  locals, variables)
- Add `# keep-sorted ... block=yes` for multi-line sorted blocks
- Data-driven pattern: define resources as maps in `locals`, iterate
  with `for_each`
- Security scanner ignore annotations inline:
  `# kics-scan ignore-line`, `# checkov:skip=CKV_...`
- Format: `tofu fmt` (canonical HCL formatting)
- Two-space indentation, align `=` signs within blocks

### Shell Scripts

- Shebang: `#!/usr/bin/env bash`; always start with `set -euo pipefail`
- UPPERCASE variables with braces: `${MY_VARIABLE}`
- Format with `shfmt`: `--case-indent --indent 2 --space-redirects`
- Lint with `shellcheck` (SC2317 excluded); two-space indentation
- Use functions for reusable logic
- Redirect stderr for logging: `echo "msg" >&2`
- Validate dependencies early: `command -v tool > /dev/null || die "..."`

### YAML

- Start files with `---`; two-space indentation
- Lint with `yamllint` (relaxed profile, line-length disabled)
- Format with `prettier` (markdown excluded from prettier)
- Use `# keep-sorted` for sorted lists

### Markdown

- Lint with `rumdl` (not markdownlint); wrap at 72 characters
- Proper heading hierarchy, language identifiers in code fences
- `CHANGELOG.md` is auto-generated and excluded from linting

### JSON

- Lint with `jsonlint --comments` (comments allowed)
- Excluded: `.devcontainer/devcontainer.json`

### GitHub Actions Workflows

- **Always validate with `actionlint`** after modifications
- Pin all actions to full SHA with version comment:
  `uses: actions/checkout@<full-sha> # v4.2.0`
- Set `permissions: read-all` at workflow level, override per-job
  with minimal permissions and inline comments
- Prefer `ubuntu-24.04-arm` runners
- Set explicit `timeout-minutes` on jobs
- Use `# keep-sorted` for env blocks

## Security

- **Secrets**: Managed via SOPS with AGE encryption (`.env.yaml`);
  never commit secrets
- **Security scanners** (all run in CI):
  Checkov (skip `CKV_GHA_7`), DevSkim (ignore DS162092, DS137138),
  KICS (HIGH only), Trivy (HIGH/CRITICAL, ignores unfixed),
  Gitleaks (pre-commit hook)

## Version Control

### Commit Messages

Conventional commits enforced by commitizen, gitlint, and commit-check.

- Format: `<type>: <description>` (lowercase, no period)
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `style`,
  `perf`, `ci`, `build`, `revert`
- Subject: imperative mood, max 72 characters
- Body: wrap at 72 chars, explain what/why, reference issues with
  `Fixes`, `Closes`, `Resolves`
- Direct commits to `main`/`master` blocked by pre-commit hook

### Branching

Conventional branch format: `<type>/<description>` --
`feature/`, `feat/`, `bugfix/`, `fix/`, `hotfix/`, `release/`,
`chore/`. Use lowercase, hyphens, no consecutive/leading/trailing
hyphens.

### Pull Requests

- Create as **draft**; title must follow conventional commit format
- Link related issues with keywords; CI must pass before merge

## Quality Checklist

- [ ] `pre-commit run --all-files` passes
- [ ] HCL formatted with `tofu fmt`
- [ ] Shell scripts pass `shellcheck` and `shfmt`
- [ ] GitHub Actions validated with `actionlint`; pinned to full SHA
- [ ] Markdown wrapped at 72 characters
- [ ] `# keep-sorted` blocks remain sorted
- [ ] No secrets or credentials in code; two-space indentation (no tabs)
