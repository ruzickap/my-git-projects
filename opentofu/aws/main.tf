terraform {
  required_version = "~> 1.11"
  required_providers {
    # keep-sorted start block=yes
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    # keep-sorted end
  }
}

locals {
  # keep-sorted start
  # File paths for AWS CLI configuration — standard locations, profile
  # sections managed by local_sensitive_file resources
  aws_config_file      = "${pathexpand("~")}/.aws/config"
  aws_credentials_file = "${pathexpand("~")}/.aws/credentials"
  aws_profile          = "my-aws"
  aws_region           = "eu-central-1"
  # Dollars — set a low budget limit for personal account to get notified of any unexpected costs immediately
  budget_limit_amount   = "5"
  github_oidc_repo      = "ruzickap/my-git-projects"
  github_oidc_role_name = "GitHubOidc-${replace(local.github_oidc_repo, "/", "-")}"
  # Policies to attach to the IAM user for AWS CLI access
  iam_managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"]
  # User name for the IAM user
  iam_user_name = "aws-cli"
  # User email address used for notifications and ownership
  my_email = "petr.ruzicka@gmail.com"
  # S3 bucket name for OpenTofu state files
  s3_bucket_name = "ruzickap-my-git-projects-opentofu-state-files"
  # keep-sorted end
}

# Access to RUZICKA_SBX01 AWS Account (/github/shared/actions-secrets/RUZICKA_SBX01_AWS_ROLE_TO_ASSUME)
variable "aws_default_access_key_id" {
  description = "Access key ID for the [default] AWS CLI profile (different account, not managed by this module)"
  type        = string
  sensitive   = true
}

# Access to RUZICKA_SBX01 AWS Account (/github/shared/actions-secrets/RUZICKA_SBX01_AWS_ROLE_TO_ASSUME) (arn:aws:iam::7xxxxx7:role/GitHubOidcFederatedRole)
variable "aws_default_role_arn" {
  description = "Role ARN for the [default] AWS CLI config profile (different account, not managed by this module)"
  type        = string
}

# Access to RUZICKA_SBX01 AWS Account (/github/shared/actions-secrets/RUZICKA_SBX01_AWS_ROLE_TO_ASSUME)
variable "aws_default_secret_access_key" {
  description = "Secret access key for the [default] AWS CLI profile (different account, not managed by this module)"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = local.aws_region
  default_tags {
    tags = {
      managed-by = "opentofu"
      owner      = local.my_email
      repository = "ruzickap/my-git-projects/opentofu/aws"
    }
  }
}

data "aws_partition" "current" {}

#trivy:ignore:AVD-AWS-0143 Personal account — single IAM user, groups/roles overhead not warranted
resource "aws_iam_user" "this" {
  # checkov:skip=CKV_AWS_273:SSO not available — personal account uses IAM user for programmatic access
  name = local.iam_user_name
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

resource "aws_iam_user_policy_attachment" "this" {
  # checkov:skip=CKV_AWS_40:Single-user personal account — no groups or roles needed
  for_each   = toset(local.iam_managed_policy_arns)
  user       = aws_iam_user.this.name
  policy_arn = each.value
}

resource "local_sensitive_file" "aws_credentials" {
  filename             = local.aws_credentials_file
  file_permission      = "0600"
  directory_permission = "0700"
  content = join("\n", [
    "# Managed by OpenTofu — ~/git/my-git-projects/opentofu/aws",
    "[default]",
    "aws_access_key_id = ${var.aws_default_access_key_id}",
    "aws_secret_access_key = ${var.aws_default_secret_access_key}",
    "",
    "[${local.aws_profile}]",
    "aws_access_key_id = ${aws_iam_access_key.this.id}",
    "aws_secret_access_key = ${aws_iam_access_key.this.secret}",
    "",
  ])
}

resource "local_sensitive_file" "aws_config" {
  filename             = local.aws_config_file
  file_permission      = "0600"
  directory_permission = "0700"
  content = join("\n", [
    "# Managed by OpenTofu — ~/git/my-git-projects/opentofu/aws",
    "[default]",
    "role_arn = ${var.aws_default_role_arn}",
    "source_profile = default",
    "",
    "[profile ${local.aws_profile}]",
    "region = ${local.aws_region}",
    "",
  ])
}

################################################################################
# S3 Bucket — OpenTofu State Files
################################################################################

#trivy:ignore:AVD-AWS-0089 Personal account — access logging not needed for state bucket
#trivy:ignore:AVD-AWS-0132 Personal account — SSE-S3 (AWS default) is sufficient, KMS CMK not needed
resource "aws_s3_bucket" "opentofu_state" {
  # checkov:skip=CKV_AWS_18:Personal account — access logging not needed for state bucket
  # checkov:skip=CKV_AWS_144:Personal account — cross-region replication not needed for state bucket
  # checkov:skip=CKV_AWS_145:Personal account — SSE-S3 (AWS default) is sufficient, KMS CMK not needed
  # checkov:skip=CKV2_AWS_62:Personal account — S3 event notifications not needed for state bucket
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
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.opentofu_state]
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
# AWS Budget — Cost Alert
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
  name                 = local.github_oidc_role_name
  description          = "Service Role for ${local.github_oidc_repo} GitHub Actions"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 7200
}

#trivy:ignore:AVD-AWS-0057 Personal account — admin privileges intentional for CI/CD full infrastructure management
resource "aws_iam_role_policy_attachment" "github_actions" {
  # checkov:skip=CKV_AWS_274:Personal account — admin privileges intentional for CI/CD full infrastructure management
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssm_parameter" "github_oidc_role_arn" {
  # checkov:skip=CKV_AWS_337:Personal account — AWS-managed key is sufficient for non-critical SSM parameters
  name  = "/github/ruzickap/my-git-projects/actions-secrets/MY_AWS_AWS_ROLE_TO_ASSUME"
  type  = "SecureString"
  value = aws_iam_role.github_actions.arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC federated IAM role"
  value       = aws_iam_role.github_actions.arn
}
