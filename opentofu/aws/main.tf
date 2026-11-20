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
      version = "6.72.0"
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
  budget_limit_amount = "2"
  # Repository whose GitHub Actions (main + pull requests) write to the DynamoDB table
  container_image_scans_github_repo = "ruzickap/container-image-scans"
  # DynamoDB table and Cognito identity pool name
  container_image_scans_name = "container-image-scans"
  # Limits the successful public reads to 2 RCU x 8 KB/s = ~42 GB/month (100 GB/month data transfer out is free).
  # Throttled requests still return small errors without limit - the read throttling alarm reports such abuse
  container_image_scans_read_capacity = 2
  # Free tier: 25 RCU + 25 WCU for all tables in the region together - lower it before adding another table
  container_image_scans_write_capacity = 25
  github_oidc_repo                     = "ruzickap/my-git-projects"
  github_oidc_role_name                = "GitHubOidc-${replace(local.github_oidc_repo, "/", "-")}"
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

  # New key first: OpenTofu authenticates with this key (AWS_PROFILE=my-aws).
  # Not on local_sensitive_file - deleting the old file would remove the new one (same path).
  lifecycle {
    create_before_destroy = true
  }
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

resource "aws_iam_role" "github_actions" {
  name        = local.github_oidc_role_name
  description = "Service Role for ${local.github_oidc_repo} GitHub Actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RoleForGitHubActions"
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
        # Only the subjects used by tofu-cloudflare-github.yml (push/schedule/dispatch on main and pull requests)
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${local.github_oidc_repo}:pull_request",
              "repo:${local.github_oidc_repo}:ref:refs/heads/main",
            ]
          }
        }
      },
      {
        Sid       = "AllowUsersToAssumeRole"
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { AWS = aws_iam_user.this.arn }
      },
    ]
  })
}

# trivy:ignore:AVD-AWS-0057 Personal account - admin privileges intentional for CI/CD full infrastructure management
resource "aws_iam_role_policy_attachment" "github_actions" {
  # checkov:skip=CKV_AWS_274:Personal account - admin privileges intentional for CI/CD full infrastructure management
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"
}

################################################################################
# Container Image Scans - DynamoDB + Cognito guest read access (AWS Always Free)
################################################################################

# Never pays - everything stays in the AWS Always Free tier:
# - PROVISIONED capacity: requests above it are throttled, not billed (no on-demand, auto scaling, GSIs)
# - no point-in-time recovery, KMS customer managed key, streams or warm throughput (all paid)
# - Cognito identity pools, IAM and STS are free; guests read the table directly (public data)
# trivy:ignore:AVD-AWS-0024 Point-in-time recovery is billed per GB-month - not in the free tier
# trivy:ignore:AVD-AWS-0025 KMS customer managed key costs $1/month - the free AWS owned key is used
resource "aws_dynamodb_table" "container_image_scans" {
  # checkov:skip=CKV_AWS_28:Point-in-time recovery is billed per GB-month - not in the free tier
  # checkov:skip=CKV_AWS_119:KMS customer managed key costs $1/month - the free AWS owned key is used
  # checkov:skip=CKV2_AWS_16:Auto scaling would raise the capacity above the free tier
  name                        = local.container_image_scans_name
  billing_mode                = "PROVISIONED"
  read_capacity               = local.container_image_scans_read_capacity
  write_capacity              = local.container_image_scans_write_capacity
  table_class                 = "STANDARD"
  deletion_protection_enabled = true
  hash_key                    = "pk"
  range_key                   = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }

  # Deleting expired items is free - the writer sets "expires_at" (epoch seconds) to keep the storage below 25 GB
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

resource "aws_cognito_identity_pool" "container_image_scans" {
  # checkov:skip=CKV_AWS_366:Guest access is intended - the GitHub Pages site reads the public scan results
  identity_pool_name = local.container_image_scans_name

  # Kill switch - stop the public reads immediately (budget / throttling alert): swap the comment of these two lines and apply
  allow_unauthenticated_identities = true
  # allow_unauthenticated_identities = false
  # Enhanced flow only - Cognito adds a scope-down session policy to the guest credentials
  allow_classic_flow = false
}

resource "aws_iam_role" "container_image_scans_guest" {
  name        = "Cognito-${local.container_image_scans_name}-guest"
  description = "Read-only access to the ${local.container_image_scans_name} DynamoDB table for Cognito guests (GitHub Pages)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "CognitoGuests"
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = "cognito-identity.amazonaws.com" }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.container_image_scans.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "container_image_scans_guest" {
  name = "ReadContainerImageScansTable"
  role = aws_iam_role.container_image_scans_guest.id

  # No dynamodb:Scan - a full table read would use up the read capacity
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadContainerImageScansTable"
        Effect   = "Allow"
        Action   = ["dynamodb:BatchGetItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.container_image_scans.arn
      },
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "container_image_scans" {
  identity_pool_id = aws_cognito_identity_pool.container_image_scans.id

  roles = {
    unauthenticated = aws_iam_role.container_image_scans_guest.arn
  }
}

resource "aws_iam_role" "github_actions_container_image_scans" {
  name        = "GitHubOidc-${replace(local.container_image_scans_github_repo, "/", "-")}"
  description = "Service Role for ${local.container_image_scans_github_repo} GitHub Actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RoleForGitHubActions"
        Effect    = "Allow"
        Action    = "sts:AssumeRoleWithWebIdentity"
        Principal = { Federated = aws_iam_openid_connect_provider.github_actions.arn }
        # Any workflow on main and pull requests; fork `pull_request` runs get no secrets or id-token,
        # but fork `pull_request_target` runs do (as main) - never run fork code there
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = [
              "repo:${local.container_image_scans_github_repo}:pull_request",
              "repo:${local.container_image_scans_github_repo}:ref:refs/heads/main",
            ]
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "github_actions_container_image_scans" {
  name = "WriteContainerImageScansTable"
  role = aws_iam_role.github_actions_container_image_scans.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteContainerImageScansTable"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
        ]
        Resource = aws_dynamodb_table.container_image_scans.arn
      },
    ]
  })
}

################################################################################
# Free tier alerts - CloudWatch alarms (10 free) + SNS e-mails (1,000/month free)
################################################################################

# trivy:ignore:AVD-AWS-0095 CloudWatch can not publish to the AWS managed SNS key, a KMS customer managed key costs $1/month
resource "aws_sns_topic" "free_tier_alerts" {
  # checkov:skip=CKV_AWS_26:CloudWatch can not publish to the AWS managed SNS key, a KMS customer managed key costs $1/month
  name = "free-tier-alerts"
}

# AWS sends a confirmation e-mail after the first apply - no alerts are delivered until it is confirmed
resource "aws_sns_topic_subscription" "free_tier_alerts_email" {
  topic_arn = aws_sns_topic.free_tier_alerts.arn
  protocol  = "email"
  endpoint  = local.my_email
}

# Read throttling = public demand above the free tier capacity (e.g. abuse of the guest access) - reported within 5 minutes.
# Writes come only from own CI (throttled writes are free and retried), so they have no alarm
resource "aws_cloudwatch_metric_alarm" "container_image_scans_read_throttling" {
  alarm_name          = "${aws_dynamodb_table.container_image_scans.name}-ReadThrottleEvents"
  alarm_description   = "DynamoDB table ${aws_dynamodb_table.container_image_scans.name}: reads throttled - public demand above the free tier capacity"
  namespace           = "AWS/DynamoDB"
  metric_name         = "ReadThrottleEvents"
  dimensions          = { TableName = aws_dynamodb_table.container_image_scans.name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.free_tier_alerts.arn]
  ok_actions          = [aws_sns_topic.free_tier_alerts.arn]
}

# HTTP 400 errors (e.g. ValidationException for an item over 400 KB) = the CI writer silently fails.
# The metric has no table dimension - it covers all DynamoDB tables in the region
resource "aws_cloudwatch_metric_alarm" "dynamodb_user_errors" {
  alarm_name          = "${aws_dynamodb_table.container_image_scans.name}-UserErrors"
  alarm_description   = "DynamoDB (${local.aws_region}): requests rejected with HTTP 400 (validation, missing table, access, ...) in the last hour"
  namespace           = "AWS/DynamoDB"
  metric_name         = "UserErrors"
  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.free_tier_alerts.arn]
  ok_actions          = [aws_sns_topic.free_tier_alerts.arn]
}

# Any cost of the services behind the free tier resources (the monthly account budget alerts at $1 only)
resource "aws_budgets_budget" "free_tier_services" {
  name         = "free-tier-services"
  budget_type  = "COST"
  limit_amount = "0.01"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "Service"
    values = ["AWS Data Transfer", "Amazon Cognito", "Amazon DynamoDB", "Amazon Simple Notification Service", "AmazonCloudWatch"]
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

output "container_image_scans_cognito_identity_pool_id" {
  description = "ID of the Cognito identity pool for the guest (GitHub Pages) read access to the container-image-scans DynamoDB table"
  value       = aws_cognito_identity_pool.container_image_scans.id
}

output "container_image_scans_dynamodb_table_name" {
  description = "Name of the container-image-scans DynamoDB table"
  value       = aws_dynamodb_table.container_image_scans.name
}

output "container_image_scans_github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC IAM role allowed to write to the container-image-scans DynamoDB table"
  value       = aws_iam_role.github_actions_container_image_scans.arn
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC federated IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "keepassxc_ssm_parameter_names" {
  description = "Names of the SSM parameters synced from KeePassXC"
  value       = sort([for p in aws_ssm_parameter.keepassxc : p.name])
}
