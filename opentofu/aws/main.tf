terraform {
  required_version = "~> 1.11"
  required_providers {
    # keep-sorted start block=yes
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # keep-sorted end
  }
}

locals {
  # keep-sorted start
  # File paths for AWS CLI configuration — standard locations, profile
  # sections managed by inline local-exec provisioners
  aws_config_file      = "${pathexpand("~")}/.aws/config"
  aws_credentials_file = "${pathexpand("~")}/.aws/credentials"
  aws_profile          = "my-aws"
  aws_region           = "eu-central-1"
  # Dollars — set a low budget limit for personal account to get notified of any unexpected costs immediately
  budget_limit_amount = "5"
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

data "aws_caller_identity" "current" {}
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

resource "terraform_data" "aws_profile" {
  input = {
    aws_access_key_id     = aws_iam_access_key.this.id
    aws_secret_access_key = aws_iam_access_key.this.secret
    aws_profile           = local.aws_profile
    aws_region            = local.aws_region
    aws_credentials_file  = local.aws_credentials_file
    aws_config_file       = local.aws_config_file
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -euo pipefail
      mkdir -p "$$(dirname "$${AWS_CREDENTIALS_FILE}")"
      chmod 700 "$$(dirname "$${AWS_CREDENTIALS_FILE}")"
      touch "$${AWS_CREDENTIALS_FILE}" "$${AWS_CONFIG_FILE}"
      chmod 600 "$${AWS_CREDENTIALS_FILE}" "$${AWS_CONFIG_FILE}"
      sed -i'' -e "/^\[$${AWS_PROFILE}\]$$/,/^\[/{ /^\[$${AWS_PROFILE}\]$$/d; /^\[/!d; }" "$${AWS_CREDENTIALS_FILE}"
      sed -i'' -e "/^\[profile $${AWS_PROFILE}\]$$/,/^\[/{ /^\[profile $${AWS_PROFILE}\]$$/d; /^\[/!d; }" "$${AWS_CONFIG_FILE}"
      printf '\n[%s]\naws_access_key_id = %s\naws_secret_access_key = %s\n' "$${AWS_PROFILE}" "$${AWS_ACCESS_KEY_ID}" "$${AWS_SECRET_ACCESS_KEY}" >> "$${AWS_CREDENTIALS_FILE}"
      printf '\n[profile %s]\nregion = %s\n' "$${AWS_PROFILE}" "$${AWS_REGION}" >> "$${AWS_CONFIG_FILE}"
    EOT
    interpreter = ["bash", "-c"]
    environment = {
      AWS_PROFILE           = self.input.aws_profile
      AWS_CREDENTIALS_FILE  = self.input.aws_credentials_file
      AWS_CONFIG_FILE       = self.input.aws_config_file
      AWS_ACCESS_KEY_ID     = self.input.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = self.input.aws_secret_access_key
      AWS_REGION            = self.input.aws_region
    }
  }

  provisioner "local-exec" {
    when        = destroy
    command     = <<-EOT
      set -euo pipefail
      [ -f "$${AWS_CREDENTIALS_FILE}" ] && sed -i'' -e "/^\[$${AWS_PROFILE}\]$$/,/^\[/{ /^\[$${AWS_PROFILE}\]$$/d; /^\[/!d; }" "$${AWS_CREDENTIALS_FILE}"
      [ -f "$${AWS_CONFIG_FILE}" ] && sed -i'' -e "/^\[profile $${AWS_PROFILE}\]$$/,/^\[/{ /^\[profile $${AWS_PROFILE}\]$$/d; /^\[/!d; }" "$${AWS_CONFIG_FILE}"
    EOT
    interpreter = ["bash", "-c"]
    environment = {
      AWS_PROFILE          = self.input.aws_profile
      AWS_CREDENTIALS_FILE = self.input.aws_credentials_file
      AWS_CONFIG_FILE      = self.input.aws_config_file
    }
  }
}

################################################################################
# S3 Bucket — OpenTofu State Files
################################################################################

#trivy:ignore:AVD-AWS-0089 Personal account — access logging not needed for state bucket
#trivy:ignore:AVD-AWS-0132 Personal account — SSE-S3 (AWS default) is sufficient, KMS CMK not needed
resource "aws_s3_bucket" "opentofu_state" {
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

locals {
  # keep-sorted start
  aws_iam_user_name     = "aws-cli"
  github_oidc_repo      = "ruzickap/my-git-projects"
  github_oidc_role_name = "GitHubOidc-${replace(local.github_oidc_repo, "/", "-")}"
  ssm_arn_prefix        = "arn:${data.aws_partition.current.partition}:ssm:${local.aws_region}:${data.aws_caller_identity.current.account_id}:parameter"
  # keep-sorted end
}

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

data "aws_iam_policy_document" "github_actions" {
  # checkov:skip=CKV_AWS_356:OIDC provider ARNs are not predictable — wildcard resource required for iam:ListOpenIDConnectProviders
  # checkov:skip=CKV_AWS_109:OIDC provider management requires wildcard resource — ARNs are generated at creation time
  statement {
    sid    = "AllowSSMParameterStore"
    effect = "Allow"
    actions = [
      # keep-sorted start
      "ssm:DeleteParameter",
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:PutParameter",
      # keep-sorted end
    ]
    resources = [
      "${local.ssm_arn_prefix}/github/ruzickap/my-git-projects/*",
      "${local.ssm_arn_prefix}/github/shared/actions-secrets/*",
    ]
  }

  statement {
    sid    = "AllowIAMRoleManagement"
    effect = "Allow"
    actions = [
      # keep-sorted start
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      # keep-sorted end
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/GitHubOidc-*"]
  }

  statement {
    sid    = "AllowOIDCProviderManagement"
    effect = "Allow"
    actions = [
      # keep-sorted start
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      # keep-sorted end
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowIAMUserRead"
    effect = "Allow"
    actions = [
      "iam:GetUser",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/${local.aws_iam_user_name}"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "GitHubActionsPolicy"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_ssm_parameter" "github_oidc_role_arn" {
  # checkov:skip=CKV_AWS_337:Personal account — AWS-managed key is sufficient for non-critical SSM parameters
  name  = "/github/ruzickap/my-git-projects/actions-secrets/AWS_ROLE_TO_ASSUME"
  type  = "SecureString"
  value = aws_iam_role.github_actions.arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC federated IAM role"
  value       = aws_iam_role.github_actions.arn
}
