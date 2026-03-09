# OpenTofu

![OpenTofu compatibility](https://img.shields.io/badge/OpenTofu-Compatible-FFDA18?logo=opentofu&logoColor=white)

This directory contains OpenTofu root modules managing personal
infrastructure. Each subdirectory is an independent module with its own
state, backend, and provider configuration.

## Modules

| Directory                                 | Description                                                      |
|-------------------------------------------|------------------------------------------------------------------|
| [`aws`](aws/)                             | AWS IAM: `aws-cli` user + S3 state bucket (local state)          |
| [`cloudflare-github`](cloudflare-github/) | Cloudflare, GitHub, Supabase, UptimeRobot, and AWS OIDC/IAM role |

The `cloudflare-github` module stores state **encrypted** (AES-GCM with
PBKDF2 key) in an AWS S3 bucket
(`ruzickap-my-git-projects-opentofu-state-files`). The `aws` module uses
a **local** state file.

## Module Dependency Order

The `aws` module **must be applied first** -- it provisions the `aws-cli`
IAM user and writes the `my-aws` profile to the standard
`~/.aws/credentials` and `~/.aws/config` files. The `cloudflare-github`
module depends on this profile (`AWS_PROFILE` is set in `mise.toml`).

```text
opentofu/aws  ──►  opentofu/cloudflare-github
```
