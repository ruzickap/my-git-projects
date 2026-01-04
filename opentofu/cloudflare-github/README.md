# OpenTofu - Cloudflare - Github

## Prerequisites

### Create CloudFlare R2 Bucket (Manual Step)

This bucket is used to store OpenTofu state files.

1. Navigate to **R2 Object Storage** → **Create bucket**

2. Configure the bucket:

   - **Bucket name**: `ruzickap-my-git-projects-opentofu-state-files`

3. Click **Create bucket**

### Create Cloudflare Account API Token

1. Navigate to **Manage Account** → **Account API Tokens**

2. Fill in the **Create Custom Token** form:

   - **Token name**: `opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)`

   - **Permissions**:
     - `Account` → `Account Settings` → `Edit` (to list accounts)
     - `Account` → `API Tokens` → `Edit` (to create/manage tokens)
     - `Account` → `Workers R2 Storage` → `Edit` (to access R2 buckets)

3. Click **Continue to summary** to review and create the token

## Run OpenTofu

This creates scoped API tokens with permissions for the main `cloudflare`
OpenTofu configuration and stores credentials as GitHub Actions secrets.

```bash
# Use the API token from "Create Cloudflare Account API Token" section
export TF_VAR_opentofu_cloudflare_github_api_token="opentofu-cloudflare-github-api-token-here"

# Generate R2 S3-compatible credentials from the Account API token
# https://developers.cloudflare.com/r2/api/tokens/#get-s3-api-credentials-from-an-api-token
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${TF_VAR_opentofu_cloudflare_github_api_token}" | jq -r '.result[0].id')
export TF_VAR_opentofu_cloudflare_github_api_token_name="opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)"
AWS_ACCESS_KEY_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/tokens" -H "Authorization: Bearer ${TF_VAR_opentofu_cloudflare_github_api_token}" | jq -r --arg name "${TF_VAR_opentofu_cloudflare_github_api_token_name}" '.result[] | select(.name == $name) | .id')
AWS_SECRET_ACCESS_KEY=$(echo -n "${TF_VAR_opentofu_cloudflare_github_api_token}" | sha256sum | cut -d' ' -f1)
AWS_S3_ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_S3_ENDPOINT

# Use the GitHub PAT
export GITHUB_TOKEN="your-github-pat-here"

tofu init
tofu apply
```

## Get OpenTofu Outputs

After applying, retrieve credentials and token values:

```bash
# Get OpenTofu Cloudflare API token and R2 credentials
tofu output cloudflare_account_token_opentofu_cloudflare_github
# Format credentials as YAML (for copying to .env.yaml)
tofu output -json cloudflare_account_token_opentofu_cloudflare_github | jq -r 'to_entries[] | "\(.key): \(.value)"'

# Retrieve specific values
tofu output -json cloudflare_web_analytics_site_ruzickap_github_io_token | jq -r
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

List all available Cloudflare API token permission names (useful when adding new
permissions to `cloudflare_account_token.tf`):

```bash
ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" -H "Authorization: Bearer ${TF_VAR_opentofu_cloudflare_github_api_token}" | jq -r '.result[0].id')

# Account-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${TF_VAR_opentofu_cloudflare_github_api_token}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account")'

# Zone-scoped permissions
curl -s "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/iam/permission_groups" -H "Authorization: Bearer ${TF_VAR_opentofu_cloudflare_github_api_token}" | jq '.result[] | select(.meta.scopes == "com.cloudflare.api.account.zone")'
```
