# OpenTofu - Cloudflare - GitHub

OpenTofu Infrastructure as Code project managing personal infrastructure across
Cloudflare, GitHub, Supabase, and UptimeRobot.

## Overview

This project provisions and manages:

- **Cloudflare** -- DNS zones with DNSSEC, DNS records, redirect rulesets,
  compression rules, cache rules, Observatory scheduled tests, Zero Trust
  tunnels and access policies, API tokens, email routing, notification policies,
  Web Analytics, and Pages projects
- **GitHub** -- repositories with settings, branch protection rulesets, Actions
  secrets, topics, workflow permissions, and GitHub Pages configuration
- **Supabase** -- Database project (`container-image-scans`) for container image
  scanning
- **UptimeRobot** -- HTTP monitors for all public domains and Zero Trust tunnel
  applications, plus a public status page (`stats.xvx.cz`)
- **AWS** -- SSM Parameter Store data sources for GitHub Actions secrets

State is stored **encrypted** (AES-GCM with PBKDF2 key) in an AWS S3 bucket.
Secrets are passed via `TF_VAR_*` environment variables.

## Architecture

### Backend

- **Type**: AWS S3
- **Bucket**: `ruzickap-my-git-projects-opentofu-state-files`
- **Encryption**: AES-GCM with PBKDF2-derived key (enforced)
- **Lock file**: Enabled (`use_lockfile = true`)

### Secrets Management

Only one OpenTofu variable (`opentofu_encryption_passphrase`) is set via
`TF_VAR_*`. All other secrets are stored in AWS SSM Parameter Store and read
at plan/apply time through `data "aws_ssm_parameter"` data sources in
`aws.tf`.

- **Local development** -- ensure the `my-aws` AWS CLI profile has permission
  to read SSM parameters, and export
  `TF_VAR_opentofu_encryption_passphrase`
- **GitHub Actions CI** -- the workflow assumes an AWS role via OIDC (so
  OpenTofu reads SSM directly) and sets
  `TF_VAR_opentofu_encryption_passphrase` from a repository secret

### Variables

Only one OpenTofu variable is defined in `variables.tf`:

| Name                             | Sensitive | Description                    |
|----------------------------------|-----------|--------------------------------|
| `opentofu_encryption_passphrase` | yes       | OpenTofu encryption passphrase |

Set it via `TF_VAR_opentofu_encryption_passphrase`.

### AWS SSM Parameters

The remaining secrets are **not** OpenTofu variables -- they are stored in
AWS SSM Parameter Store and read at plan/apply time via
`data "aws_ssm_parameter"` data sources in `aws.tf`. No `TF_VAR_*` export
is needed for these; the AWS provider reads them directly from SSM using
the `my-aws` profile (local) or OIDC role (CI).

The parameter names are the `name` / `arn` arguments in `aws.tf`:
`/github/<repo>/actions-secrets/<SECRET>` (per repository),
`/github/shared/actions-secrets/<SECRET>` (shared) and
`/xvx.cz/<app>/BASIC_AUTH_*` (Basic Auth Workers). Most of them are created
from KeePassXC by the [`opentofu/aws`](../aws/) module.

### Outputs

| Name                                               | Sensitive |
|----------------------------------------------------|-----------|
| `basic_auth_apps_urls`                             | yes       |
| `supabase_container_image_scans_apikeys`           | yes       |
| `supabase_container_image_scans_endpoint`          | no        |
| `supabase_container_image_scans_database_password` | yes       |
| `supabase_container_image_scans_env_yaml`          | yes       |

## Managed Resources

### Cloudflare DNS Zones

Each zone has DNSSEC enabled, minimum TLS 1.3 enforced, Zstandard compression
(with Brotli and Gzip fallbacks), and cache rules for static file extensions
(shared by all zones in `cloudflare_zones.tf`).

| Zone          | Email Provider           | Features                                                                             |
|---------------|--------------------------|--------------------------------------------------------------------------------------|
| `mylabs.dev`  | Mailtrap                 | Redirect to `petr.ruzicka.dev`, AWS Route 53 NS delegation (`aws`, `k8s` subdomains) |
| `ruzicka.dev` | Cloudflare Email Routing | Blog redirect (`blog.ruzicka.dev` to `ruzickap.github.io`), GoatCounter analytics    |
| `xvx.cz`      | Google Workspace         | Zero Trust tunnel CNAME records, UptimeRobot status page redirect (`stats.xvx.cz`)   |

### Cloudflare Zero Trust

Tunnels (`gate`, `gate-bracha`, `raspi`) publish the home applications on the
`xvx.cz` domain. The tunnels, applications, services and tags are listed in
`local.cloudflare_zero_trust_tunnels_applications` in `cloudflare_zero_trust.tf`.
Every application - SSH hostnames included - has a Cloudflare Access
application, so SSH needs a login too (`cloudflared access ssh` opens the
browser).

Access policies:

- **Google SSO Access** -- email-based allow policy
- **UptimeRobot Direct Access** -- service auth (`non_identity`) policy for the
  `UptimeRobot` service token, which the UptimeRobot monitors send as
  `cf-access-client-id` / `cf-access-client-secret` headers (an IP list bypass
  would let in every UptimeRobot customer)
- **Allow All** -- bypass policy (used by `hass-rpi`)

### Cloudflare API Tokens

| Token Name                                          | Permissions                     |
|-----------------------------------------------------|---------------------------------|
| `opentofu-cloudflare-github`                        | 11 account + 7 zone permissions |
| `cloudflare-account-token-pages-xvx-cz`             | Pages Write                     |
| `cloudflare-account-token-pages-petr-ruzicka-dev`   | Pages Write                     |
| `cloudflare-account-token-pages-ruzickap-github-io` | Pages Write                     |

Main token account-scoped permissions: Access (Apps and Policies,
Organizations/Identity Providers/Groups, Service Tokens), Account API Tokens,
Account Settings, Cloudflare Tunnel, Email Routing Addresses, Pages, Workers
Scripts, Zero Trust.

Main token zone-scoped permissions: Cache Settings, DNS, Dynamic URL Redirects,
Response Compression, Workers Routes, Zone Settings, Zone.

### Cloudflare Notification Policies

Email alerts (`cloudflare_notification_policy.tf`):

| Alert                               | Type                                |
|-------------------------------------|-------------------------------------|
| Expiring Access Service Token Alert | `expiring_service_token_alert`      |
| Passive Origin Monitoring           | `real_origin_monitoring`            |
| Web Analytics Metrics Update        | `web_analytics_metrics_update`      |
| Tunnel Health Alert                 | `tunnel_health_event` (all tunnels) |

### Cloudflare Pages Projects

| Project              | Production Branch |
|----------------------|-------------------|
| `petr-ruzicka-dev`   | `main`            |
| `ruzickap-github-io` | `main`            |
| `xvx-cz`             | `main`            |

### Cloudflare Workers -- Basic Auth Apps

Simple HTML pages behind HTTP Basic Auth, served by a shared Worker script and
bound to their own hostname via `cloudflare_workers_custom_domain`:

| Worker        | Hostname      |
|---------------|---------------|
| `app1-xvx-cz` | `app1.xvx.cz` |
| `app2-xvx-cz` | `app2.xvx.cz` |
| `app3-xvx-cz` | `app3.xvx.cz` |

Credentials are read from AWS SSM Parameter Store
(`/xvx.cz/<app>/BASIC_AUTH_USERNAME` and `/xvx.cz/<app>/BASIC_AUTH_PASSWORD`).
See [Get OpenTofu Outputs](#get-opentofu-outputs) for how to retrieve
ready-to-use URLs with embedded credentials.

### Cloudflare Web Analytics

| Site                    | Auto Install |
|-------------------------|--------------|
| `brewwatch.lovable.app` | no           |
| `ruzickap.github.io`    | no           |

### GitHub Repositories

All repositories in `local.github_repositories` and
`local.github_repositories_existing` (`github-repositories.tf`) are managed
with consistent settings:

- Squash merge only (merge commits and rebase merging disabled)
- Auto-delete head branches on merge
- Apache 2.0 license (default)
- Vulnerability alerts enabled
- Secret scanning with push protection (public repos)
- Branch protection rulesets on default branch (public repos): 1 required
  approving review, code owner review, linear history, status checks
- Renovate bot bypass for direct update branches
- Default Actions secrets applied to all repositories (Slack bot token and
  channel ID)

### UptimeRobot

HTTP monitors (300s interval) for:

- All public CNAME records across `xvx.cz`, `ruzicka.dev`, and `mylabs.dev`
- All non-SSH Zero Trust tunnel applications (they pass Cloudflare Access with
  the `UptimeRobot` service token)
- Proxied A records on `xvx.cz`

Public status page: `stats.xvx.cz`

### Supabase

- **Project**: `container-image-scans` (us-east-1)
- Random 16-character database password

### AWS

GitHub Actions secrets are read from AWS SSM Parameter Store at
`/github/<repo>/actions-secrets/<secret>` (per-repo) and
`/github/shared/actions-secrets/<secret>` (shared defaults).

The AWS provider uses the `my-aws` profile from the standard
`~/.aws/credentials` and `~/.aws/config` files (the `AWS_PROFILE` env var is
set in `mise.toml`), provisioned by the [`opentofu/aws`](../aws/) module.

The `aws-cli` IAM user is managed in the separate [`opentofu/aws`](../aws/) module.

## Prerequisites

### Apply the `opentofu/aws` Module First

The AWS provider in this module uses the `my-aws` profile from the standard
`~/.aws/credentials` file (the `AWS_PROFILE` env var is set in `mise.toml`).
The profile is created by the [`opentofu/aws`](../aws/) module. You **must**
run `tofu apply` there before initializing this module, otherwise the AWS
provider fails with:

```text
Error: failed to get shared config profile, my-aws
```

See the [`opentofu/aws` README](../aws/README.md) for bootstrap instructions.

### Create Cloudflare Account API Token

1. Navigate to **Manage Account** -> **Account API Tokens**

2. Fill in the **Create Custom Token** form:

   | Token Name                                                                         |
   |------------------------------------------------------------------------------------|
   | `opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)` |

   | Permission | Access             | Purpose |
   |------------|--------------------|---------|
   | `Account`  | `Account Settings` | `Edit`  |
   | `Account`  | `API Tokens`       | `Edit`  |

3. Click **Continue to summary** to review and create the token

## Run OpenTofu

Provision all managed resources (Cloudflare zones, DNS, Zero Trust, API
tokens, GitHub repositories with Actions secrets, Supabase, UptimeRobot).
All provider credentials are read from AWS SSM Parameter Store at
plan/apply time -- only the encryption passphrase must be provided.

With mise, the `init` / `plan` / `apply` tasks in `mise.toml` wrap `tofu` in
`fnox exec`, which reads `TF_VAR_opentofu_encryption_passphrase` from AWS SSM
Parameter Store (`fnox.toml`). The generic `tofu` task does the same for any
other command (e.g. `mise run tofu output`, `mise run tofu state list`):

```bash
mise run init
mise run plan
mise run apply
```

With fnox shell activation (`eval "$(fnox activate zsh)"`) the secret is
loaded when entering this directory, so plain `tofu` commands work too.

Without mise / fnox:

```bash
# The only TF_VAR_* variable required
export TF_VAR_opentofu_encryption_passphrase="..."

# Ensure the my-aws profile exists (created by opentofu/aws)
export AWS_PROFILE=my-aws

tofu init
tofu apply
```

## Get OpenTofu Outputs

After applying - retrieve outputs (reading the encrypted state needs the
passphrase - prefix with `mise run` if fnox shell activation is not enabled,
e.g. `mise run tofu output`):

```bash
# List all outputs
tofu output

# Get Supabase endpoint
tofu output supabase_container_image_scans_endpoint

# Get sensitive outputs (e.g., Supabase API keys)
tofu output -json supabase_container_image_scans_apikeys | jq -r 'to_entries[] | "\(.key): \(.value)"'

# Get Basic Auth-protected app URLs (appN.xvx.cz) with embedded credentials
tofu output -json basic_auth_apps_urls | jq -r 'to_entries[] | "\(.key): \(.value)"'
```

## Notes

### List Cloudflare API Token Permissions

Retrieve all available permission names when adding new permissions to
`cloudflare_account_token.tf`:

```bash
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r '.result[0].id')

# Account-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account")'

# Zone-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account.zone")'
```

### Container Testing (Clean Environment)

Test the OpenTofu configuration in an isolated container to ensure it works from
scratch without local dependencies:

```console
docker run -it --rm -v "${PWD}:/mnt" alpine

cd /mnt || exit
apk add --no-cache curl jq opentofu

export TF_VAR_opentofu_encryption_passphrase="..."

# Ensure the my-aws profile exists (created by opentofu/aws)
export AWS_PROFILE=my-aws

tofu init
tofu plan
```

or

```console
docker run -it --rm -v "${PWD}:/mnt" alpine

cd /mnt || exit
apk add --no-cache bash mise
# shellcheck disable=SC2016 # Single quotes intentional - expansion happens when .bashrc is sourced
echo 'eval "$(/usr/bin/mise activate bash)"' >> ~/.bashrc
bash

mise trust --yes
export TF_VAR_opentofu_encryption_passphrase="..."

mise up
tofu init
tofu plan
```
