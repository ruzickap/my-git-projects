terraform {
  encryption {
    key_provider "pbkdf2" "main" {
      # SHA-512 (128 hex characters) of the KeePassXC password - PBKDF2 requires min. 16 characters
      passphrase = sha512(var.keepassxc_password)
    }
    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }
    state {
      method   = method.aes_gcm.main
      enforced = true
    }
    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
  required_version = "~> 1.12"
  required_providers {
    # keep-sorted start block=yes
    aws = {
      source  = "hashicorp/aws"
      version = "6.69.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
    # keep-sorted end
  }
}

locals {
  # keep-sorted start
  # File paths for AWS CLI configuration - standard locations, profile sections managed by local_sensitive_file resources
  aws_config_file      = "${pathexpand("~")}/.aws/config"
  aws_credentials_file = "${pathexpand("~")}/.aws/credentials"
  aws_profile          = "my-aws"
  aws_region           = "eu-central-1"
  # Dollars - set a low budget limit for personal account to get notified of any unexpected costs immediately
  budget_limit_amount   = "5"
  github_oidc_repo      = "ruzickap/my-git-projects"
  github_oidc_role_name = "GitHubOidc-${replace(local.github_oidc_repo, "/", "-")}"
  # Policies to attach to the IAM user for AWS CLI access
  iam_managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"]
  # User name for the IAM user
  iam_user_name = "aws-cli"
  # KeePassXC database - the same path is used by the mise "enter" hook (mise.toml)
  keepassxc_database = pathexpand("~/Documents/secrets/keepass2.kdbx")
  # KeePassXC group with the SSM parameters - one entry per parameter (UserName: name, Notes: description)
  keepassxc_group = "aws-ssm-parameter-store"
  # KeePassXC key file - the same path is used by the mise "enter" hook (mise.toml)
  keepassxc_key_file = pathexpand("~/Documents/secrets/keepass.key")
  # User email address used for notifications and ownership
  my_email = "petr.ruzicka@gmail.com"
  # S3 bucket name for OpenTofu state files
  s3_bucket_name = "ruzickap-my-git-projects-opentofu-state-files"
  # keep-sorted end

  # KeePassXC entries of the group by Title (UserName: SSM parameter name, Notes: description)
  keepassxc_entries = {
    for entry in csvdecode(data.local_command.keepassxc_export.stdout) : entry.Title => {
      username = entry.Username
      # Multi-line Notes => single-line description, lines separated by "; "
      description = join("; ", compact([for line in split("\n", replace(entry.Notes, "\r", "")) : trimspace(line)]))
      password    = sensitive(entry.Password)
    }
  }
}

variable "keepassxc_password" {
  description = "Password of the KeePassXC database (set via TF_VAR_keepassxc_password environment variable), its SHA-512 hash encrypts the OpenTofu state and plan"
  type        = string
  ephemeral   = true
  sensitive   = true
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      managed-by = "opentofu"
      owner      = local.my_email
      repository = "https://github.com/ruzickap/my-git-projects/tree/main/opentofu/aws"
    }
  }
}

data "aws_partition" "current" {}

# trivy:ignore:AVD-AWS-0143 Personal account - single IAM user, groups/roles overhead not warranted
resource "aws_iam_user" "this" {
  # checkov:skip=CKV_AWS_273:SSO not available - personal account uses IAM user for programmatic access
  name = local.iam_user_name
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy_attachment" "this" {
  # checkov:skip=CKV_AWS_40:Single-user personal account - no groups or roles needed
  for_each   = toset(local.iam_managed_policy_arns)
  user       = aws_iam_user.this.name
  policy_arn = each.value
}

# [default] profile = RUZICKA_SBX01 AWS account (not managed by this module) - values from the KeePassXC entries (Title)
resource "local_sensitive_file" "aws_credentials" {
  filename             = local.aws_credentials_file
  file_permission      = "0600"
  directory_permission = "0700"
  content              = <<-EOT
    # Managed by OpenTofu - ~/git/my-git-projects/opentofu/aws
    [default]
    aws_access_key_id = ${local.keepassxc_entries["aws_access_key_id"].password}
    aws_secret_access_key = ${local.keepassxc_entries["aws_secret_access_key"].password}

    [${local.aws_profile}]
    aws_access_key_id = ${aws_iam_access_key.this.id}
    aws_secret_access_key = ${aws_iam_access_key.this.secret}
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "local_sensitive_file" "aws_config" {
  filename             = local.aws_config_file
  file_permission      = "0600"
  directory_permission = "0700"
  content              = <<-EOT
    # Managed by OpenTofu - ~/git/my-git-projects/opentofu/aws
    [default]
    role_arn = ${local.keepassxc_entries["ruzicka_sbx01_aws_role_to_assume"].password}
    source_profile = default

    [profile ${local.aws_profile}]
    region = ${local.aws_region}
  EOT
}

################################################################################
# S3 Bucket - OpenTofu State Files
################################################################################

# trivy:ignore:AVD-AWS-0089 Personal account - access logging not needed for state bucket
# trivy:ignore:AVD-AWS-0132 Personal account - SSE-S3 (AWS default) is sufficient, KMS CMK not needed
resource "aws_s3_bucket" "opentofu_state" {
  # checkov:skip=CKV_AWS_18:Personal account - access logging not needed for state bucket
  # checkov:skip=CKV_AWS_144:Personal account - cross-region replication not needed for state bucket
  # checkov:skip=CKV_AWS_145:Personal account - SSE-S3 (AWS default) is sufficient, KMS CMK not needed
  # checkov:skip=CKV2_AWS_62:Personal account - S3 event notifications not needed for state bucket
  bucket = local.s3_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "opentofu_state" {
  bucket = aws_s3_bucket.opentofu_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "opentofu_state" {
  bucket = aws_s3_bucket.opentofu_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "opentofu_state" {
  bucket = aws_s3_bucket.opentofu_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "opentofu_state" {
  bucket = aws_s3_bucket.opentofu_state.id

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  rule {
    id     = "expire-noncurrent-versions"
    status = aws_s3_bucket_versioning.opentofu_state.versioning_configuration[0].status == "Enabled" ? "Enabled" : "Disabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "opentofu_state" {
  bucket = aws_s3_bucket.opentofu_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.opentofu_state.arn,
          "${aws_s3_bucket.opentofu_state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.opentofu_state]
}

################################################################################
# AWS Budget - Cost Alert
################################################################################

resource "aws_budgets_budget" "monthly" {
  name         = "monthly-account-budget"
  budget_type  = "COST"
  limit_amount = local.budget_limit_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [local.my_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [local.my_email]
  }
}

################################################################################
# AWS IAM roles and policies for GitHub Actions OIDC federation
################################################################################

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "RoleForGitHubActions"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_oidc_repo}:*"]
    }
  }

  statement {
    sid     = "AllowUsersToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.this.arn]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = local.github_oidc_role_name
  description        = "Service Role for ${local.github_oidc_repo} GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# trivy:ignore:AVD-AWS-0057 Personal account - admin privileges intentional for CI/CD full infrastructure management
resource "aws_iam_role_policy_attachment" "github_actions" {
  # checkov:skip=CKV_AWS_274:Personal account - admin privileges intentional for CI/CD full infrastructure management
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

################################################################################
# SSM Parameters - synced from KeePassXC
################################################################################

data "local_command" "keepassxc_export" {
  command = "bash"
  # Script via stdin, paths/group as arguments (no shell escaping needed); password from env TF_VAR_keepassxc_password
  # yq keeps only the group entries (header + Title, Username, Password, Notes); CSV output keeps values like "0123" intact
  arguments = ["-o", "pipefail", "-s", local.keepassxc_database, local.keepassxc_key_file, local.keepassxc_group]
  stdin     = <<-EOT
    printf '%s\n' "$${TF_VAR_keepassxc_password:?Environment variable TF_VAR_keepassxc_password (KeePass password) is not set}" |
      keepassxc-cli export --format csv --key-file "$2" "$1" |
      GROUP="$3" yq -p csv -o csv --csv-auto-parse=false '[["Title", "Username", "Password", "Notes"]] + [.[] | select(.Group | sub("^[^/]*/"; "") == strenv(GROUP)) | [.Title, .Username, .Password, .Notes]]'
  EOT

  lifecycle {
    # Protection against destroying all SSM parameters (wrong group, empty group, ...)
    postcondition {
      condition     = length(csvdecode(self.stdout)) > 0
      error_message = "No entries found in the KeePassXC group \"${local.keepassxc_group}\""
    }
  }
}

resource "aws_ssm_parameter" "keepassxc" {
  # checkov:skip=CKV_AWS_337:Personal account - AWS-managed key is sufficient for SSM parameters
  for_each = local.keepassxc_entries

  name        = each.value.username
  description = each.value.description
  type        = "SecureString"
  value       = sensitive(each.value.password)

  lifecycle {
    precondition {
      condition     = each.value.username != ""
      error_message = "KeePassXC entry \"${local.keepassxc_group}/${each.key}\" must have UserName (SSM parameter name)"
    }
    precondition {
      condition     = each.value.description != "" && length(each.value.description) <= 1024
      error_message = "Notes (SSM parameter description) of the KeePassXC entry \"${local.keepassxc_group}/${each.key}\" must be non-empty and max. 1024 characters long (current length: ${length(each.value.description)})"
    }
    precondition {
      condition     = length([for entry in local.keepassxc_entries : entry.username if entry.username == each.value.username]) == 1
      error_message = "UserName (SSM parameter name) \"${each.value.username}\" is used by more than one KeePassXC entry"
    }
  }
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC federated IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "keepassxc_ssm_parameter_names" {
  description = "Names of the SSM parameters synced from KeePassXC"
  value       = sort([for p in aws_ssm_parameter.keepassxc : p.name])
}
