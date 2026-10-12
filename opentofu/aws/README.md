# OpenTofu - AWS

OpenTofu Infrastructure as Code project managing AWS IAM, S3 and SSM Parameter
Store resources for personal infrastructure.

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
- **SSM Parameters from KeePassXC** -- every entry of the KeePassXC group
  `aws-ssm-parameter-store` (`~/Documents/secrets/keepass2.kdbx`) is pushed to
  SSM Parameter Store (`eu-central-1`) as a `SecureString` parameter

State is stored in a **local** file (`terraform.tfstate`), **encrypted** using
OpenTofu state encryption (the plan files too).

## Architecture

### Backend

- **Type**: Local (default)
- **Encryption**: `pbkdf2` key provider + `aes_gcm` method for state and plan
  (both `enforced` - unencrypted state or plan files are rejected).
  The passphrase is the SHA-512 hash of the KeePassXC database password
  (`sha512(var.keepassxc_password)`, always 128 characters) - one password
  protects the KeePassXC database and the state

### AWS CLI Files

Both `~/.aws/credentials` and `~/.aws/config` are **fully managed** by
`local_sensitive_file` resources. OpenTofu owns the entire file content, so any
external modification (manual edits, other tools) is detected via content hash
comparison and corrected on the next `tofu apply`.

Each file contains two profiles:

- **`[default]`** -- credentials and role ARN for a separate AWS account,
  read from the KeePassXC group `aws-ssm-parameter-store` (see
  [`[default]` profile values](#default-profile-values))
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

The role ARN is stored in the SSM parameter
`/github/ruzickap/my-git-projects/actions-secrets/MY_AWS_AWS_ROLE_TO_ASSUME`
by the KeePassXC entry `aws_role_to_assume` (like all other SSM parameters).

### SSM Parameters from KeePassXC (`aws_ssm_parameter.keepassxc`)

The KeePassXC database `~/Documents/secrets/keepass2.kdbx` (password + key file
`~/Documents/secrets/keepass.key`) is the source of truth for the SSM
parameters. Every entry of the group `aws-ssm-parameter-store` becomes one
`SecureString` parameter:

| KeePassXC field | SSM parameter                                     |
|-----------------|---------------------------------------------------|
| Title           | `for_each` key (`aws_ssm_parameter.keepassxc[…]`) |
| UserName        | Name, e.g. `/github/shared/actions-secrets/NAME`  |
| Password        | Value (may be multi-line)                         |
| Notes           | Description - lines joined with `;`               |

How it works:

1. `data "local_command" "keepassxc_export"` runs a `bash` script (passed via
   `stdin`) that calls `keepassxc-cli export --format csv` (single database
   unlock). The database, key file and group are passed as positional
   arguments, so no shell escaping is needed. The password comes from the
   `TF_VAR_keepassxc_password` environment variable inside the shell, so it is
   never a data source argument or part of an error message.
2. [`yq`](https://github.com/mikefarah/yq) filters the CSV and passes only
   the entries of the group (columns Title, Username, Password, Notes) to
   OpenTofu - the rest of the personal KeePassXC database never reaches
   OpenTofu or the state. The output stays CSV - `yq` would convert values
   like `0123`, `true` or `null` to numbers / booleans in JSON output.
3. The CSV is parsed by `csvdecode()`. The passwords are marked `sensitive()`
   in `local.keepassxc_entries`.

> [!NOTE]
> The `local` provider does not mark the `stdout` of `local_command` as
> sensitive, so `tofu show` / `tofu state show
> data.local_command.keepassxc_export` print the passwords of the group in
> plain text. The state and plan files themselves are encrypted.

`tofu plan` fails (nothing is changed) when:

- `TF_VAR_keepassxc_password` is not set or the password is wrong
- the group does not exist or has no entries (protection against destroying
  all SSM parameters)
- an entry has an empty UserName, or empty / longer than 1024 characters Notes
- two entries share the same UserName

| Change in KeePassXC                         | Result after `tofu apply`              |
|---------------------------------------------|----------------------------------------|
| Add an entry                                | SSM parameter created                  |
| Change Password or Notes                    | SSM parameter updated in place         |
| Change UserName                             | Old parameter deleted, new one created |
| Rename the Title                            | Parameter deleted and created again    |
| Delete the entry / move it out of the group | SSM parameter **deleted**              |

Use a `moved` block to rename a Title without re-creating the parameter, and a
`removed` block (`lifecycle { destroy = false }`) to stop managing a parameter
without deleting it.

### `[default]` profile values

The `[default]` AWS CLI profile belongs to a different AWS account (Ruzicka
SBX01) and is **not** managed by this module. Its values are the passwords of
these KeePassXC entries (Title) in the same group:

| `[default]` profile value | KeePassXC entry (Title)            | SSM parameter (UserName)                                          |
|---------------------------|------------------------------------|-------------------------------------------------------------------|
| `aws_access_key_id`       | `aws_access_key_id`                | `/account/aws/ruzicka_sbx01/aws-cli/aws_access_key_id`            |
| `aws_secret_access_key`   | `aws_secret_access_key`            | `/account/aws/ruzicka_sbx01/aws-cli/aws_secret_access_key`        |
| `role_arn`                | `ruzicka_sbx01_aws_role_to_assume` | `/github/shared/actions-secrets/RUZICKA_SBX01_AWS_ROLE_TO_ASSUME` |

The entries are referenced as `local.keepassxc_entries["<Title>"].password` in the
`local_sensitive_file` resources - `tofu plan` fails (`Invalid index`) if one
of them is missing. The entries are pushed to SSM Parameter Store as well, like
all other entries of the group.

### Inputs

| Name                 | Sensitive                  | Description                                                      |
|----------------------|----------------------------|------------------------------------------------------------------|
| `keepassxc_password` | yes (sensitive, ephemeral) | KeePassXC password, its SHA-512 hash encrypts the state and plan |

The KeePassXC database (`~/Documents/secrets/keepass2.kdbx`), key file
(`~/Documents/secrets/keepass.key`) and group (`aws-ssm-parameter-store`) are
fixed in `locals` (`keepassxc_database`, `keepassxc_key_file`,
`keepassxc_group`). The mise `enter` hook verifies the password against the
same database and key file (`mise.toml`) - change the paths in both files.

`keepassxc_password` must be set as the environment variable
`TF_VAR_keepassxc_password` (the mise `enter` hook does it, see
[Tooling](#tooling)) - the interactive OpenTofu prompt is not enough, because
`keepassxc-cli` reads the password from the environment variable directly.

### Outputs

| Name                            | Sensitive | Description                                       |
|---------------------------------|-----------|---------------------------------------------------|
| `github_oidc_role_arn`          | no        | ARN of the GitHub Actions OIDC IAM role           |
| `keepassxc_ssm_parameter_names` | no        | Names of the SSM parameters synced from KeePassXC |

## Prerequisites

### Tooling

This module uses [mise](https://mise.jdx.dev/) for tool version management.
`mise.toml` pins OpenTofu `1.13.1` and `yq` and sets `AWS_PROFILE=my-aws` and
`AWS_REGION=eu-central-1`. `keepassxc-cli` (KeePassXC) must be installed.

The KeePassXC database `~/Documents/secrets/keepass2.kdbx` (password + key file
`~/Documents/secrets/keepass.key`), group `aws-ssm-parameter-store`, is read by
`main.tf` and used for:

- the SSM parameters
- the `[default]` AWS CLI profile values
- the state and plan encryption (SHA-512 hash of the password)

When you enter the directory, a mise `enter` hook asks for the KeePass
password, exports it as `TF_VAR_keepassxc_password` and verifies it by
unlocking the database (`keepassxc-cli db-info`). The `leave` hook unsets the
variable:

```bash
cd ~/git/my-git-projects/opentofu/aws || exit
# 🔑 KeePass password for ~/Documents/secrets/keepass2.kdbx:
# ✅ KeePass password is correct   (or: ❌ Wrong KeePass password)
```

The hooks are defined for `zsh`. After a wrong password, leave and re-enter
the directory to try again.

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

2. **Store the `[default]` profile values in KeePassXC** - group
   `aws-ssm-parameter-store` in `~/Documents/secrets/keepass2.kdbx` (see
   [`[default]` profile values](#default-profile-values)). `main.tf` reads them
   from there, `tofu plan` fails if they are missing.

3. **Run the first `tofu apply`** using the temporary credentials:

   ```bash
   export AWS_ACCESS_KEY_ID="temporary-access-key-id"
   export AWS_SECRET_ACCESS_KEY="temporary-secret-access-key"
   read -rs TF_VAR_keepassxc_password && export TF_VAR_keepassxc_password # done by the mise "enter" hook
   tofu init
   tofu apply
   ```

   This provisions the `aws-cli` IAM user, generates its access key, and writes
   both `~/.aws/credentials` and `~/.aws/config` with the `[default]` and
   `[my-aws]` profiles.

4. **Verify the files** were created:

   ```bash
   cat ~/.aws/credentials
   ```

   Expected output:

   ```ini
   # Managed by OpenTofu - ~/git/my-git-projects/opentofu/aws
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
   # Managed by OpenTofu - ~/git/my-git-projects/opentofu/aws
   [default]
   role_arn = arn:aws:iam::ACCOUNT:role/ROLE
   source_profile = default

   [profile my-aws]
   region = eu-central-1
   ```

5. **Delete the temporary IAM user** from the AWS Console:
   - Go to **IAM** -> **Users** -> `tmp-opentofu-bootstrap`
   - Delete the access key, then delete the user

   Subsequent `tofu apply` runs use the `aws-cli` credentials from the
   `[my-aws]` profile in `~/.aws/credentials`.

6. **Store the GitHub Actions role ARN in KeePassXC** - the ARN exists only
   after the first apply. Put the output `github_oidc_role_arn` into the
   KeePassXC entry `aws_role_to_assume` (UserName
   `/github/ruzickap/my-git-projects/actions-secrets/MY_AWS_AWS_ROLE_TO_ASSUME`)
   and run `tofu apply` again:

   ```bash
   tofu output -raw github_oidc_role_arn
   ```

## Run OpenTofu

After the initial bootstrap (see above), subsequent runs use the `[my-aws]`
profile from the standard `~/.aws/credentials`. `mise.toml` sets
`AWS_PROFILE=my-aws` and `AWS_REGION=eu-central-1` automatically, and the
KeePass password is exported when you enter the directory:

```bash
tofu init
tofu plan
tofu apply
```

Always check the `to destroy` count in `tofu plan` - deleting an SSM parameter
is permanent, including its version history.

## Changing the KeePassXC password

The KeePassXC password also encrypts the state, so the state must be
re-encrypted after changing it. Add the old password as a `fallback` key
provider, run `tofu apply` (the state is written with the new key) and remove
the fallback again:

```hcl
key_provider "pbkdf2" "old" {
  passphrase = sha512("old-keepassxc-password")
}
method "aes_gcm" "old" {
  keys = key_provider.pbkdf2.old
}
state {
  method = method.aes_gcm.main
  fallback {
    method = method.aes_gcm.old
  }
}
```

Losing the KeePassXC password means losing access to both the KeePassXC
database and the state.
