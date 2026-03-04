# OpenTofu - Cloudflare - GitHub

OpenTofu Infrastructure as Code project managing personal infrastructure
across Cloudflare, GitHub, Supabase, and UptimeRobot.

## Overview

This project provisions and manages:

- **Cloudflare** -- DNS zones with DNSSEC, DNS records, redirect rulesets,
  compression rules, cache rules, Observatory scheduled tests, Zero Trust
  tunnels and access policies, API tokens, email routing, notification
  policies, Web Analytics, and Pages projects
- **GitHub** -- repositories with settings, branch protection rulesets,
  Actions secrets, topics, workflow permissions, and GitHub Pages
  configuration
- **Supabase** -- Database project (`container-image-scans`) for container
  image scanning
- **UptimeRobot** -- HTTP monitors for all public domains and Zero Trust
  tunnel applications, plus a public status page (`stats.xvx.cz`)

State is stored **encrypted** (AES-GCM with PBKDF2 key) in a Cloudflare R2
bucket. Secrets are managed via **SOPS** (AGE encryption) in `.env.yaml`.

## Architecture

### Backend

- **Type**: S3-compatible (Cloudflare R2)
- **Bucket**: `ruzickap-my-git-projects-opentofu-state-files`
- **Encryption**: AES-GCM with PBKDF2-derived key (enforced)
- **Lock file**: Enabled (`use_lockfile = true`)

### Secrets Management (SOPS + AGE)

Secrets are stored in `.env.yaml`, encrypted with
[SOPS](https://github.com/getsops/sops) using
[AGE](https://age-encryption.org/) encryption. The AGE private key is
resolved differently depending on the environment:

- **Local development (mise)** -- mise reads the key from a file on disk.
  Two settings in `mise.toml` control this:
  - `SOPS_AGE_KEY_FILE` env var points to
    `~/Documents/secrets/age-my-git-projects.txt` (used by the `sops` CLI
    and OpenTofu `sops` provider)
  - `sops.age_key_file` setting points to the same file (used by mise's
    built-in SOPS integration to decrypt `.env.yaml` via
    `_.file = ".env.yaml"`)
- **GitHub Actions CI** -- the workflow sets the `SOPS_AGE_KEY` environment
  variable directly from `${{ secrets.SOPS_AGE_KEY }}`. SOPS prefers the
  inline key (`SOPS_AGE_KEY`) over the file path (`SOPS_AGE_KEY_FILE`)
  when both are present.

### Variables

| Name                                  | Type     | Description                                                        |
|---------------------------------------|----------|--------------------------------------------------------------------|
| `opentofu_encryption_passphrase`      | `string` | OpenTofu encryption passphrase (required)                          |
| `gh_token_opentofu_cloudflare_github` | `string` | GitHub PAT for managing Cloudflare and GitHub resources (required) |

Both variables are marked as sensitive.

### Outputs

| Name                                                  | Sensitive |
|-------------------------------------------------------|-----------|
| `cloudflare_account_token_opentofu_cloudflare_github` | yes       |
| `supabase_container_image_scans_apikeys`              | yes       |
| `supabase_container_image_scans_endpoint`             | no        |
| `supabase_container_image_scans_database_password`    | yes       |
| `supabase_container_image_scans_env_yaml`             | yes       |

## Managed Resources

### Cloudflare DNS Zones

Each zone has DNSSEC enabled, minimum TLS 1.3 enforced, Zstandard
compression (with Brotli and Gzip fallbacks), and cache rules for static
file extensions.

| Zone          | Email Provider           | Features                                                                             |
|---------------|--------------------------|--------------------------------------------------------------------------------------|
| `mylabs.dev`  | Mailtrap                 | Redirect to `petr.ruzicka.dev`, AWS Route 53 NS delegation (`aws`, `k8s` subdomains) |
| `ruzicka.dev` | Cloudflare Email Routing | Blog redirect (`blog.ruzicka.dev` to `ruzickap.github.io`), GoatCounter analytics    |
| `xvx.cz`      | Google Workspace         | Zero Trust tunnel CNAME records, UptimeRobot status page redirect (`stats.xvx.cz`)   |

### Cloudflare Zero Trust

Two tunnels (`gate`, `raspi`) hosting 14 applications on the `xvx.cz`
domain:

| Tunnel  | Application       | Service                  | Tags                      |
|---------|-------------------|--------------------------|---------------------------|
| `gate`  | `gate`            | `https://127.0.0.1`      | lan, router, wan          |
| `gate`  | `gate-ssh`        | `ssh://127.0.0.1:22`     | lan, router, ssh, wan     |
| `gate`  | `msr-2`           | `http://192.168.1.4`     | iot, wifi                 |
| `gate`  | `transmission`    | `http://127.0.0.1:9091`  | router                    |
| `gate`  | `uzg-01`          | `http://192.168.1.3`     | iot, lan                  |
| `raspi` | `alloy-rpi`       | `http://localhost:12345` | rpi, wifi                 |
| `raspi` | `esphome-rpi`     | `http://localhost:6052`  | container, iot, rpi, wifi |
| `raspi` | `grafana-rpi`     | `http://localhost:3001`  | rpi, wifi                 |
| `raspi` | `hass-rpi`        | `http://localhost:8123`  | container, iot, rpi, wifi |
| `raspi` | `kodi-rpi`        | `http://localhost:8080`  | rpi, wifi                 |
| `raspi` | `prometheus-rpi`  | `http://localhost:9090`  | rpi, wifi                 |
| `raspi` | `rpi`             | `http://127.0.0.1:3000`  | container, rpi, wifi      |
| `raspi` | `rpi-ssh`         | `ssh://127.0.0.1:22`     | rpi, ssh, wifi            |
| `raspi` | `zigbee2mqtt-rpi` | `http://localhost:8082`  | container, iot, rpi, wifi |

Access policies:

- **Google SSO Access** -- email-based allow policy
- **UptimeRobot Direct Access** -- bypass policy using UptimeRobot IP list
- **Allow All** -- bypass policy (used by `hass-rpi`)

### Cloudflare API Tokens

| Token Name                                          | Permissions                     |
|-----------------------------------------------------|---------------------------------|
| `opentofu-cloudflare-github`                        | 11 account + 6 zone permissions |
| `cloudflare-account-token-pages-xvx-cz`             | Pages Write                     |
| `cloudflare-account-token-pages-petr-ruzicka-dev`   | Pages Write                     |
| `cloudflare-account-token-pages-ruzickap-github-io` | Pages Write                     |

Main token account-scoped permissions: Access (Apps and Policies,
Organizations/Identity Providers/Groups, Service Tokens), Account API
Tokens, Account Settings, Cloudflare Tunnel, Email Routing Addresses,
Pages, Workers R2 Storage, Zero Trust.

Main token zone-scoped permissions: Cache Settings, DNS, Dynamic URL
Redirects, Response Compression, Zone Settings, Zone.

### Cloudflare Notification Policies

| Alert                               | Type                           |
|-------------------------------------|--------------------------------|
| Abuse Report Alert                  | `abuse_report_alert`           |
| Expiring Access Service Token Alert | `expiring_service_token_alert` |
| Passive Origin Monitoring           | `real_origin_monitoring`       |
| Web Analytics Metrics Update        | `web_analytics_metrics_update` |
| Incident Alert                      | `incident_alert` (critical)    |
| Usage Based Billing (R2 > 100 MB)   | `billing_usage_alert`          |
| Tunnel Health Alert                 | `tunnel_health_event`          |

### Cloudflare Pages Projects

| Project              | Production Branch |
|----------------------|-------------------|
| `petr-ruzicka-dev`   | `main`            |
| `ruzickap-github-io` | `main`            |
| `xvx-cz`             | `main`            |

### Cloudflare Web Analytics

| Site                    | Auto Install |
|-------------------------|--------------|
| `brewwatch.lovable.app` | no           |
| `ruzickap.github.io`    | no           |

### GitHub Repositories

27 repositories managed with consistent settings:

- Squash/rebase merge only (merge commits disabled)
- Auto-delete head branches on merge
- Apache 2.0 license (default)
- Vulnerability alerts enabled
- Secret scanning with push protection (public repos)
- Branch protection rulesets on default branch (public repos): 2 required
  reviews, code owner review, linear history, status checks
- Renovate bot bypass for direct update branches
- Default Actions secrets applied to all repositories (Renovate app
  credentials, Slack bot token)

### UptimeRobot

HTTP monitors (300s interval) for:

- All public CNAME records across `xvx.cz`, `ruzicka.dev`, and `mylabs.dev`
- All non-SSH Zero Trust tunnel applications
- Proxied A records on `xvx.cz`

Public status page: `stats.xvx.cz`

### Supabase

- **Project**: `container-image-scans` (us-east-1)
- Random 16-character database password

## Prerequisites

### Create Cloudflare R2 Bucket (Manual Step)

This bucket is used to store OpenTofu state files.

1. Navigate to **R2 Object Storage** -> **Create bucket**

2. Configure the bucket:

   - **Bucket name**:
     `ruzickap-my-git-projects-opentofu-state-files`

3. Click **Create bucket**

### Create Cloudflare Account API Token

1. Navigate to **Manage Account** -> **Account API Tokens**

2. Fill in the **Create Custom Token** form:

   | Token Name                                                                         |
   |------------------------------------------------------------------------------------|
   | `opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)` |

   | Permission | Access               | Purpose |
   |------------|----------------------|---------|
   | `Account`  | `Account Settings`   | `Edit`  |
   | `Account`  | `API Tokens`         | `Edit`  |
   | `Account`  | `Workers R2 Storage` | `Edit`  |

3. Click **Continue to summary** to review and create the token

## Run OpenTofu

This creates scoped API tokens with permissions for the main `cloudflare`
OpenTofu configuration and stores credentials as GitHub Actions secrets.

```bash
# Use the API token from "Create Cloudflare Account API Token" section
export OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN="opentofu-cloudflare-github-api-token-here"
# Use the GitHub PAT
export TF_VAR_gh_token_opentofu_cloudflare_github="your-github-pat-here"

# Generate R2 S3-compatible credentials from the Account API token
# https://developers.cloudflare.com/r2/api/tokens/#get-s3-api-credentials-from-an-api-token
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r '.result[0].id')
export OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN_NAME="opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)"
AWS_ACCESS_KEY_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/tokens" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r --arg name "${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN_NAME}" '.result[] | select(.name == $name) | .id')
AWS_SECRET_ACCESS_KEY=$(echo -n "${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | sha256sum | cut -d' ' -f1)
AWS_S3_ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_S3_ENDPOINT

tofu init
tofu apply
```

## Get OpenTofu Outputs

After applying -- retrieve credentials:

```bash
# Get OpenTofu Cloudflare API token and R2 credentials
tofu output cloudflare_account_token_opentofu_cloudflare_github
# Format credentials as YAML (for copying to .env.yaml)
tofu output -json cloudflare_account_token_opentofu_cloudflare_github | jq -r 'to_entries[] | "\(.key): \(.value)"'
```

The output contains the following environment variables:

| Variable                               | Description                        |
|----------------------------------------|------------------------------------|
| `CLOUDFLARE_R2_ACCESS_KEY_ID`          | R2 S3-compatible Access Key ID     |
| `CLOUDFLARE_R2_ENDPOINT_URL_S3`        | R2 S3-compatible endpoint URL      |
| `CLOUDFLARE_R2_SECRET_ACCESS_KEY`      | R2 S3-compatible Secret Access Key |
| `OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN` | Cloudflare API token for OpenTofu  |

## Update `.env.yaml`

Export the credentials to `.env.yaml`:

```bash
tofu output -json cloudflare_account_token_opentofu_cloudflare_github | jq -r 'to_entries[] | "\(.key): \(.value)"'
sops edit .env.yaml
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

Test the OpenTofu configuration in an isolated container to ensure it
works from scratch without local dependencies:

```console
docker run -it --rm -v "${PWD}:/mnt" alpine

cd /mnt || exit
apk add --no-cache curl jq opentofu

export TF_VAR_opentofu_encryption_passphrase="p...E"
export SOPS_AGE_KEY="AGE-SECRET-KEY..."
export OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN="opentofu-cloudflare-github-api-token-here"
export TF_VAR_gh_token_opentofu_cloudflare_github="gh...m"

# Generate R2 S3-compatible credentials from the Account API token
# https://developers.cloudflare.com/r2/api/tokens/#get-s3-api-credentials-from-an-api-token
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r '.result[0].id')
export OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN_NAME="opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)"
AWS_ACCESS_KEY_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/tokens" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r --arg name "${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN_NAME}" '.result[] | select(.name == $name) | .id')
AWS_SECRET_ACCESS_KEY=$(echo -n "${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | sha256sum | cut -d' ' -f1)
AWS_S3_ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_S3_ENDPOINT

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

mise trust --yes && export SOPS_AGE_KEY="AGE-SECRET-KEY-1...X" # Needed by Mise + Tofu + SOPS
export TF_VAR_gh_token_opentofu_cloudflare_github="gh...m"

mise up
tofu init
tofu plan
```
