# Guards in main.tf that stop a bad KeePassXC export from deleting SSM parameters.
# The export is replaced with fixed CSV and the providers are mocked: no KeePassXC, AWS or ~/.aws writes.
mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}
mock_provider "local" {}

run "empty_group_fails" {
  command = plan

  override_data {
    target = data.local_command.keepassxc_export
    values = {
      stdout = "Title,Username,Password,Notes\n"
    }
  }

  expect_failures = [data.local_command.keepassxc_export]
}

run "duplicate_ssm_parameter_name_fails" {
  command = plan

  override_data {
    target = data.local_command.keepassxc_export
    values = {
      stdout = <<-EOT
        Title,Username,Password,Notes
        aws_access_key_id,/test/duplicate,AKIAEXAMPLE,Access key
        aws_secret_access_key,/test/duplicate,secret,Secret key
        ruzicka_sbx01_aws_role_to_assume,/test/role,arn:aws:iam::123456789012:role/test,Role ARN
      EOT
    }
  }

  expect_failures = [aws_ssm_parameter.keepassxc]
}
