mock_provider "aws" {
  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws"
    }
  }
}
mock_provider "local" {}

variables {
  aws_default_access_key_id     = "mock-access-key-id"
  aws_default_role_arn          = "arn:aws:iam::123456789012:role/GitHubOidcFederatedRole"
  aws_default_secret_access_key = "test"
}

run "iam_user_name" {
  command = plan

  assert {
    condition     = aws_iam_user.this.name == "aws-cli"
    error_message = "IAM user name should be 'aws-cli'"
  }
}

run "s3_bucket_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.opentofu_state.bucket == "ruzickap-my-git-projects-opentofu-state-files"
    error_message = "S3 bucket name should match local.s3_bucket_name"
  }
}

run "s3_bucket_versioning_enabled" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.opentofu_state.versioning_configuration[0].status == "Enabled"
    error_message = "S3 bucket versioning should be enabled"
  }
}

run "s3_public_access_blocked" {
  command = plan

  assert {
    condition     = aws_s3_bucket_public_access_block.opentofu_state.block_public_acls == true
    error_message = "S3 bucket should block public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.opentofu_state.block_public_policy == true
    error_message = "S3 bucket should block public policy"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.opentofu_state.ignore_public_acls == true
    error_message = "S3 bucket should ignore public ACLs"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.opentofu_state.restrict_public_buckets == true
    error_message = "S3 bucket should restrict public buckets"
  }
}

run "s3_bucket_ownership_enforced" {
  command = plan

  assert {
    condition     = aws_s3_bucket_ownership_controls.opentofu_state.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "S3 bucket ownership should be BucketOwnerEnforced"
  }
}

run "budget_configuration" {
  command = plan

  assert {
    condition     = aws_budgets_budget.monthly.name == "monthly-account-budget"
    error_message = "Budget name should be 'monthly-account-budget'"
  }

  assert {
    condition     = aws_budgets_budget.monthly.budget_type == "COST"
    error_message = "Budget type should be COST"
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "5"
    error_message = "Budget limit should be 5 USD"
  }

  assert {
    condition     = aws_budgets_budget.monthly.limit_unit == "USD"
    error_message = "Budget limit unit should be USD"
  }

  assert {
    condition     = aws_budgets_budget.monthly.time_unit == "MONTHLY"
    error_message = "Budget time unit should be MONTHLY"
  }
}

run "github_oidc_provider" {
  command = plan

  assert {
    condition     = aws_iam_openid_connect_provider.github_actions.url == "https://token.actions.githubusercontent.com"
    error_message = "OIDC provider URL should be GitHub Actions token endpoint"
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.github_actions.client_id_list, "sts.amazonaws.com")
    error_message = "OIDC provider client ID list should contain sts.amazonaws.com"
  }
}

run "github_oidc_role" {
  command = plan

  assert {
    condition     = aws_iam_role.github_actions.name == "GitHubOidc-ruzickap-my-git-projects"
    error_message = "GitHub OIDC role name should match expected pattern"
  }
}

run "ssm_parameter_path" {
  command = plan

  assert {
    condition     = aws_ssm_parameter.github_oidc_role_arn.name == "/github/ruzickap/my-git-projects/actions-secrets/MY_AWS_AWS_ROLE_TO_ASSUME"
    error_message = "SSM parameter name should match expected path"
  }

  assert {
    condition     = aws_ssm_parameter.github_oidc_role_arn.type == "SecureString"
    error_message = "SSM parameter should be SecureString type"
  }
}

run "iam_policy_attachment" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.github_actions.policy_arn == "arn:aws:iam::aws:policy/AdministratorAccess"
    error_message = "GitHub Actions role should have AdministratorAccess policy"
  }
}

run "local_files_permissions" {
  command = plan

  assert {
    condition     = local_sensitive_file.aws_credentials.file_permission == "0600"
    error_message = "AWS credentials file should have 0600 permissions"
  }

  assert {
    condition     = local_sensitive_file.aws_config.file_permission == "0600"
    error_message = "AWS config file should have 0600 permissions"
  }
}
