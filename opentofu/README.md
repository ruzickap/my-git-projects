# OpenTofu

![OpenTofu compatibility](https://img.shields.io/badge/OpenTofu-Compatible-FFDA18?logo=opentofu&logoColor=white)

This directory contains OpenTofu root modules managing personal infrastructure.
Each subdirectory is an independent module with its own state, backend, and
provider configuration.

## Modules

| Directory                                 | Description                                                                       |
|-------------------------------------------|-----------------------------------------------------------------------------------|
| [`aws`](aws/)                             | AWS IAM: `aws-cli` user, S3 state bucket, GitHub Actions OIDC, SSM from KeePassXC |
| [`cloudflare-github`](cloudflare-github/) | Cloudflare, GitHub, Supabase, UptimeRobot, and AWS OIDC/IAM role                  |

The `cloudflare-github` module stores state **encrypted** (AES-GCM with PBKDF2
key) in an AWS S3 bucket (`ruzickap-my-git-projects-opentofu-state-files`). The
`aws` module uses a **local** state file, **encrypted** with the SHA-512 hash of
the KeePassXC password.

## Module Dependency Order

The `aws` module **must be applied first** -- it provisions the `aws-cli` IAM
user and writes the `my-aws` profile to the standard `~/.aws/credentials` and
`~/.aws/config` files. The `cloudflare-github` module depends on this profile
(`AWS_PROFILE` is set in `mise.toml`).

The `aws` module reads its secrets - the SSM parameters and the `[default]` AWS
CLI profile (a separate account not managed by the module) - from the KeePassXC
database `~/Documents/secrets/keepass2.kdbx` (key file
`~/Documents/secrets/keepass.key`), group `aws-ssm-parameter-store`. It requires
the KeePassXC password, which the mise `enter` hook in `opentofu/aws` asks for:

```bash
read -rs TF_VAR_keepassxc_password && export TF_VAR_keepassxc_password
```

See [`aws/README.md`](aws/README.md) for the KeePassXC entries and the
bootstrap.

```text
opentofu/aws  ──►  opentofu/cloudflare-github
```
