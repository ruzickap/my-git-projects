# AGENTS.md

Repo-specific notes for `ruzickap/my-git-projects`. General linting, commit,
branch, and PR conventions live in the shared `~/.config/opencode/AGENTS.md`
and are not repeated here. This file only captures what an agent would
otherwise get wrong.

## What this repo actually is

This is **not** an application. It is the owner's personal control plane:

- `gh-repo-defaults/` - template files that multi-gitter **copies into ~30
  other repositories**. Editing a file here changes every downstream repo on
  the next multi-gitter run, not just this one.
- `multi-gitter/` - the engine that distributes `gh-repo-defaults/`
  (`config.yaml` + `multi-gitter-run-script.sh`).
- `opentofu/` - two independent OpenTofu root modules managing the owner's
  real AWS / Cloudflare / GitHub / UptimeRobot infrastructure.
- `cloudformation/gh-action-iam-role-oidc.yaml` - OIDC provider and
  `GitHubOidcFederatedRole` for the separate RUZICKA_SBX01 AWS account,
  deployed manually by `aws-cloudformation-gh-action.yml`. Not the same
  resources as the OpenTofu `aws` module (that one manages the `my-aws`
  account).
- `README.md` is a personal git/`gh` command cheatsheet. It does **not**
  document this repo's architecture - do not treat it as such.

## This repo dogfoods its own defaults

The root config files (`.mega-linter.yml`, `.rumdl.toml`, `.checkov.yml`,
`lychee.toml`, `SECURITY.md`, `.github/workflows/*`) are **copies** of the
files under `gh-repo-defaults/my-defaults/`. They are plain copies, not
symlinks.

- When you change a shared config, update **both** the root copy and the
  `gh-repo-defaults/my-defaults/` copy, or they silently drift.
- This repo is processed by multi-gitter as `ruzickap/my-git-projects` with the
  `all` MegaLinter flavor (see `multi-gitter-run-script.sh`).

## AGENTS.md is special - do not let it get overwritten

- `copy_defaults()` copies defaults with `--exclude AGENTS.md`, so this file is
  **never** overwritten by a normal multi-gitter run.
- The run script only seeds `AGENTS.md` from `gh-repo-defaults/my-defaults/`
  (then runs `opencode run` with a prompt that rewrites it for the repo) when a
  target repo has **no** `AGENTS.md`.
- Therefore `gh-repo-defaults/my-defaults/AGENTS.md` is a generic starter
  template. This root `AGENTS.md` is meant to be repo-specific and to diverge
  from it. Do not "fix" the divergence by resetting this file to the default.

## OpenTofu - how to run modules

Both modules use [mise](https://mise.jdx.dev/) (`mise.toml`), which pins the
`opentofu` version and exports `AWS_PROFILE=my-aws` / `AWS_REGION=eu-central-1`.
`cloudflare-github` uses `fnox` (`fnox.toml`) to inject `TF_VAR_*` secrets from
AWS SSM Parameter Store via `fnox exec` wrapped in mise tasks - run
`mise run init` / `mise run plan` / `mise run apply` (or the generic
`mise run tofu <args>`, e.g. `mise run tofu output`) there (the archived
`mise-env-fnox` plugin is no longer used). `aws` reads its secrets from
KeePassXC (see below); with mise active, just run `tofu init` and `tofu plan` /
`tofu apply` inside that module dir.

- `opentofu/aws/` - **local** state, **encrypted** with the SHA-512 hash of the
  KeePassXC password (`TF_VAR_keepassxc_password`, exported by the mise `enter`
  hook which prompts for it). Reads `~/Documents/secrets/keepass2.kdbx` (+
  `keepass.key`) via `keepassxc-cli` + `yq`: every entry of the group
  `aws-ssm-parameter-store` becomes an SSM parameter, the `[default]` AWS CLI
  profile values come from entries of the same group. Must be applied
  **first**: it provisions the `aws-cli` IAM user and writes the
  `~/.aws/credentials` / `~/.aws/config` `[my-aws]` profile that the other
  module depends on. First-ever apply needs a manual bootstrap (temporary admin
  key) - see `opentofu/aws/README.md`.
- `opentofu/cloudflare-github/` - **encrypted** S3 remote state (AES-GCM via
  PBKDF2). Requires `TF_VAR_opentofu_encryption_passphrase`; without it `tofu
  init` against existing state will fail.
- Provider versions are **pinned exactly** in `main.tf` (e.g. `aws = 6.48.0`);
  Renovate bumps them. Keep `required_providers` blocks sorted (`keep-sorted`).
- `opentofu/aws/` runs `tofu test` in CI (`tofu-aws-tests.yml`):
  `main.tftest.hcl` checks the KeePassXC -> SSM guards and that the DynamoDB
  table stays in the AWS free tier, with mocked providers. `cloudflare-github`
  has no automated tests (it touches live infra).

## Gotchas worth knowing

- `local_sensitive_file` in `opentofu/aws/` **fully owns** `~/.aws/credentials`
  and `~/.aws/config`. A `tofu apply` overwrites any manual edits to those
  files. Both modules' `[default]` profile points at a *different* AWS account
  whose creds come from KeePassXC entries (read by `opentofu/aws/`) and are not
  module-managed.
- The local `terraform_validate` pre-commit hook runs `terraform` by default,
  which can not read the encrypted `opentofu/aws` state - set
  `PCT_TFPATH=tofu` (as in CI).
- CI applies `opentofu/cloudflare-github` automatically on push to `main` and
  on PRs labeled `tofu-apply`; the weekly schedule runs a drift check that
  opens an issue. Changing files there is a live infrastructure change.
- On push to `main`, `tf-via-pr` applies the plan saved on the merged PR - a
  direct push (no PR) has no plan and fails. Renovate therefore merges
  provider bumps there as one grouped PR (`packageRules` in
  `.github/renovate-global.json5`).
- Only one `tofu-cloudflare-github` plan should run at a time: parallel plans
  hit UptimeRobot's API rate limit (HTTP 429). The workflow plans on label
  events only for the `tofu-apply` / `tofu-plan` labels.
- The CI AWS role (`GitHubOidc-ruzickap-my-git-projects`, AdministratorAccess)
  trusts only the `ref:refs/heads/main` and `pull_request` OIDC subjects. Give
  `id-token: write` only to jobs that assume it.
- `checkov:skip` / `trivy:ignore` inline comments in the `.tf` files are
  intentional (personal-account tradeoffs). Don't remove them to "fix" a scan.
- The `prettier` pre-commit hook **excludes `*.md`**; Markdown is formatted by
  `rumdl` instead. `CHANGELOG.md` is excluded from every linter and is
  generated by release-please - never hand-edit it.
- Branch protection blocks direct commits to `main`/`master`
  (`no-commit-to-branch`). Work on a `chore/`, `feat/`, or `fix/` branch.
