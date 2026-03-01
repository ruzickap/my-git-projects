# OpenTofu - Cloudflare - GitHub

OpenTofu Infrastructure as Code project managing personal
infrastructure across Cloudflare, GitHub, Supabase, and
UptimeRobot.

## Overview

This project provisions and manages:

- **Cloudflare** -- DNS zones (`mylabs.dev`, `ruzicka.dev`,
  `xvx.cz`), DNS records, page rules, Zero Trust tunnels and
  access applications, API tokens, notification policies,
  Web Analytics sites, and Pages projects
- **GitHub** -- 27 repositories (settings, branch protection
  rulesets, Actions secrets, topics, workflow permissions)
- **Supabase** -- Database project for container image scanning
- **UptimeRobot** -- HTTP monitors for all public domains and
  Zero Trust tunnel applications, plus a public status page

State is stored **encrypted** (AES-GCM with PBKDF2 key) in a
Cloudflare R2 bucket. Secrets are managed via **SOPS** (AGE
encryption) in `.env.yaml`.

## Architecture

### Backend

- **Type**: S3-compatible (Cloudflare R2)
- **Bucket**: `ruzickap-my-git-projects-opentofu-state-files`
- **Encryption**: AES-GCM with PBKDF2-derived key (enforced)

### Variables

| Name                                  | Type     | Description                                  |
|---------------------------------------|----------|----------------------------------------------|
| `opentofu_encryption_passphrase`      | `string` | OpenTofu encryption passphrase (required)    |
| `gh_token_opentofu_cloudflare_github` | `string` | GitHub PAT for managing resources (required) |

Both variables are marked as sensitive.

### Outputs

| Name                                                  | Sensitive |
|-------------------------------------------------------|-----------|
| `cloudflare_account_token_opentofu_cloudflare_github` | yes       |
| `supabase_container_image_scans_apikeys`              | yes       |
| `supabase_container_image_scans_endpoint`             | no        |
| `supabase_container_image_scans_database_password`    | yes       |
| `supabase_container_image_scans_env_yaml`             | yes       |

## Prerequisites

### Create Cloudflare R2 Bucket (Manual Step)

This bucket is used to store OpenTofu state files.

1. Navigate to **R2 Object Storage** -> **Create bucket**

2. Configure the bucket:

   - **Bucket name**:
     `ruzickap-my-git-projects-opentofu-state-files`

3. Click **Create bucket**

### Create Cloudflare Account API Token

1. Navigate to **Manage Account** ->
   **Account API Tokens**

2. Fill in the **Create Custom Token** form:

   | Token Name                                                                         |
   |------------------------------------------------------------------------------------|
   | `opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)` |

   | Permission | Access               | Purpose |
   |------------|----------------------|---------|
   | `Account`  | `Account Settings`   | `Edit`  |
   | `Account`  | `API Tokens`         | `Edit`  |
   | `Account`  | `Workers R2 Storage` | `Edit`  |

3. Click **Continue to summary** to review and create
   the token

## Run OpenTofu

This creates scoped API tokens with permissions for the
main `cloudflare` OpenTofu configuration and stores
credentials as GitHub Actions secrets.

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

Retrieve all available permission names when adding new
permissions to `cloudflare_account_token.tf`:

```bash
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq -r '.result[0].id')

# Account-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account")'

# Zone-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account.zone")'
```

### Container Testing (Clean Environment)

Test the OpenTofu configuration in an isolated container
to ensure it works from scratch without local dependencies:

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
