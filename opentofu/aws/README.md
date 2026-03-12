# OpenTofu - AWS

OpenTofu Infrastructure as Code project managing AWS IAM and S3 resources for
personal infrastructure.

## Overview

This project provisions and manages:

- **IAM User** -- `aws-cli` with programmatic access and `AdministratorAccess`;
  access key credentials written to the `[my-aws]` profile in
  `~/.aws/credentials`
- **AWS CLI Files** -- `~/.aws/credentials` and `~/.aws/config` are fully
  managed by `local_sensitive_file` resources; any external drift is detected and
  corrected on the next `tofu apply`
- **S3 Bucket** -- `ruzickap-my-git-projects-opentofu-state-files` for
  OpenTofu remote state storage (used by `cloudflare-github` module)
- **Budget Alert** -- monthly $5 USD cost budget with email notifications at
  50% actual and 100% actual spend
- **GitHub Actions OIDC** -- OpenID Connect identity provider and
  `GitHubOidc-ruzickap-my-git-projects` IAM role for keyless CI authentication
  with `AdministratorAccess` for full infrastructure management

State is stored in a **local** file (`terraform.tfstate`).

## Architecture

### Backend

- **Type**: Local (default)

### AWS CLI Files

Both `~/.aws/credentials` and `~/.aws/config` are **fully managed** by
`local_sensitive_file` resources. OpenTofu owns the entire file content, so any
external modification (manual edits, other tools) is detected via content hash
comparison and corrected on the next `tofu apply`.

Each file contains two profiles:

- **`[default]`** -- credentials and role ARN for a separate AWS account,
  passed via input variables (`var.aws_default_*`)
- **`[my-aws]`** / **`[profile my-aws]`** -- credentials from the `aws-cli`
  IAM user managed by this module, plus the region

The `~/.aws/` directory is created automatically with `0700` permissions if it
does not exist. Both files are written with `0600` permissions.

`opentofu/cloudflare-github/` uses `mise.toml` to set:

- `AWS_PROFILE=my-aws`

Since the credentials are in the standard `~/.aws/credentials` and
`~/.aws/config` files, no `AWS_SHARED_CREDENTIALS_FILE` or `AWS_CONFIG_FILE`
overrides are needed.

## Managed Resources

### IAM User (`aws-cli`)

Programmatic access user with `AdministratorAccess`. An access key is generated
and written to the `[my-aws]` profile in `~/.aws/credentials`.

### S3 Bucket (`ruzickap-my-git-projects-opentofu-state-files`)

Stores OpenTofu state files for the `cloudflare-github` module. Configured
with:

- **Versioning** -- enabled (allows state recovery)
- **Encryption** -- SSE-S3 (AES-256), AWS default since January 2023
- **Public access** -- all public access blocked
- **Ownership** -- `BucketOwnerEnforced` (ACLs disabled)
- **Lifecycle rules** -- abort incomplete multipart uploads after 7 days;
  expire noncurrent object versions after 90 days
- **Bucket policy** -- deny all non-HTTPS requests
- **Deletion protection** -- `prevent_destroy = true`

### Budget Alert (`monthly-account-budget`)

Monthly cost budget set to $5 USD. Email notifications are sent to
`petr.ruzicka@gmail.com` when:

- **Actual** spend exceeds **50%** ($2.50)
- **Actual** spend exceeds **100%** ($5.00)

### GitHub Actions OIDC (`GitHubOidc-ruzickap-my-git-projects`)

OpenID Connect identity provider (`token.actions.githubusercontent.com`) and a
single IAM role for keyless GitHub Actions authentication from
`ruzickap/my-git-projects`.

The role has the `AdministratorAccess` AWS managed policy attached, granting
full access to all AWS services. This is intentional for a personal account where
the CI/CD pipeline manages the complete infrastructure (IAM, S3, SSM, OIDC,
budgets, etc.).

The role is assumable via OIDC federation by `repo:ruzickap/my-git-projects:*`
and via `sts:AssumeRole` by the `aws-cli` IAM user.

### Inputs

| Name                            | Sensitive | Description                                           |
|---------------------------------|-----------|-------------------------------------------------------|
| `aws_default_access_key_id`     | yes       | Access key ID for the `[default]` AWS CLI profile     |
| `aws_default_role_arn`          | no        | Role ARN for the `[default]` AWS CLI config profile   |
| `aws_default_secret_access_key` | yes       | Secret access key for the `[default]` AWS CLI profile |

All three variables belong to a different AWS account and are **not** managed by
this module. Pass them via `TF_VAR_*` environment variables.

### Outputs

| Name                   | Sensitive | Description                             |
|------------------------|-----------|-----------------------------------------|
| `github_oidc_role_arn` | no        | ARN of the GitHub Actions OIDC IAM role |

## Prerequisites

### Tooling

This module uses [mise](https://mise.jdx.dev/) for tool version management and
[fnox](https://github.com/jdx/mise-env-fnox) for secret injection. `mise.toml`
pins OpenTofu `1.11.5`, installs `fnox`, sets `AWS_PROFILE=my-aws` and
`AWS_REGION=eu-central-1`, and loads `TF_VAR_*` secrets from SSM Parameter Store
via `fnox.toml`.

### Initialize the AWS (Chicken-and-Egg)

OpenTofu provisions the `aws-cli` IAM user with an access key and writes the
`[my-aws]` profile into `~/.aws/credentials` and `~/.aws/config`. However, the
AWS provider needs valid credentials for the first run. To break this circular
dependency:

1. **Create a temporary IAM user** in the AWS Console:
   - Go to **IAM** -> **Users** -> **Create user**
   - User name: `tmp-opentofu-bootstrap`
   - Attach the `AdministratorAccess` managed policy directly
   - Create an access key (**Security credentials** -> **Create access key**)
   - Save the Access Key ID and Secret Access Key

2. **Run the first `tofu apply`** using the temporary credentials. `fnox`
   cannot retrieve secrets yet (SSM parameters do not exist), so pass all
   variables manually:

   ```bash
   export AWS_ACCESS_KEY_ID="temporary-access-key-id"
   export AWS_SECRET_ACCESS_KEY="temporary-secret-access-key"
   export TF_VAR_aws_default_access_key_id="default-profile-access-key-id"
   export TF_VAR_aws_default_secret_access_key="default-profile-secret"
   export TF_VAR_aws_default_role_arn="arn:aws:iam::ACCOUNT:role/ROLE"
   tofu init
   tofu apply
   ```

   This provisions the `aws-cli` IAM user, generates its access key, and writes
   both `~/.aws/credentials` and `~/.aws/config` with the `[default]` and
   `[my-aws]` profiles.

3. **Verify the files** were created:

   ```bash
   cat ~/.aws/credentials
   ```

   Expected output:

   ```ini
   # Managed by OpenTofu — ~/git/my-git-projects/opentofu/aws
   [default]
   aws_access_key_id = AKIA...
   aws_secret_access_key = ...

   [my-aws]
   aws_access_key_id = AKIA...
   aws_secret_access_key = ...
   ```

   ```bash
   cat ~/.aws/config
   ```

   Expected output:

   ```ini
   # Managed by OpenTofu — ~/git/my-git-projects/opentofu/aws
   [default]
   role_arn = arn:aws:iam::ACCOUNT:role/ROLE
   source_profile = default

   [profile my-aws]
   region = eu-central-1
   ```

4. **Delete the temporary IAM user** from the AWS Console:
   - Go to **IAM** -> **Users** -> `tmp-opentofu-bootstrap`
   - Delete the access key, then delete the user

   Subsequent `tofu apply` runs use the `aws-cli` credentials from the
   `[my-aws]` profile in `~/.aws/credentials`.

5. **Create SSM parameters** for the `[default]` profile credentials manually.
   These are **not** managed by OpenTofu and must exist in SSM Parameter Store
   so that `fnox` can retrieve them for subsequent runs:

   ```bash
   aws ssm put-parameter --region eu-central-1 --profile my-aws \
     --name "/account/aws/ruzicka_sbx01/aws-cli/aws_access_key_id" \
     --description "AWS access key ID for Ruzicka SBX01 account" \
     --type "SecureString" --value "AxxxxxU"
   aws ssm put-parameter --region eu-central-1 --profile my-aws \
     --name "/account/aws/ruzicka_sbx01/aws-cli/aws_secret_access_key" \
     --description "AWS secret access key for Ruzicka SBX01 account" \
     --type "SecureString" --value "WPxxxxxxS"
   ```

## Run OpenTofu

After the initial bootstrap (see above), subsequent runs use the `[my-aws]`
profile from the standard `~/.aws/credentials`. `mise.toml` sets
`AWS_PROFILE=my-aws` and `AWS_REGION=eu-central-1` automatically, and `fnox`
retrieves `TF_VAR_*` secrets from SSM Parameter Store (configured in
`fnox.toml`):

```bash
tofu init
tofu apply
```
