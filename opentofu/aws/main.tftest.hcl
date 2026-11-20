# Guards in main.tf:
# - a bad KeePassXC export must not delete SSM parameters
# - the container-image-scans DynamoDB table must stay in the AWS Always Free tier
# The export is replaced with fixed CSV and the providers are mocked: no KeePassXC, AWS or ~/.aws writes.
mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
  # The alarm and the e-mail subscription validate the ARN
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:eu-central-1:123456789012:cloudwatch-alarms"
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

run "dynamodb_stays_in_free_tier" {
  command = plan

  override_data {
    target = data.local_command.keepassxc_export
    values = {
      stdout = <<-EOT
        Title,Username,Password,Notes
        aws_access_key_id,/test/aws_access_key_id,AKIAEXAMPLE,Access key
        aws_secret_access_key,/test/aws_secret_access_key,secret,Secret key
        ruzicka_sbx01_aws_role_to_assume,/test/role,arn:aws:iam::123456789012:role/test,Role ARN
      EOT
    }
  }

  assert {
    condition     = aws_dynamodb_table.container_image_scans.billing_mode == "PROVISIONED" && aws_dynamodb_table.container_image_scans.table_class == "STANDARD"
    error_message = "The free tier covers only PROVISIONED capacity of the STANDARD table class"
  }

  assert {
    condition     = aws_dynamodb_table.container_image_scans.read_capacity <= 2
    error_message = "Max. 2 RCU - the public reads must stay below the 100 GB/month free data transfer out (2 RCU x 8 KB/s = ~42 GB/month)"
  }

  assert {
    condition     = aws_dynamodb_table.container_image_scans.write_capacity <= 25
    error_message = "The free tier covers max. 25 WCU (for all tables in the region together)"
  }

  assert {
    condition     = !aws_dynamodb_table.container_image_scans.point_in_time_recovery[0].enabled && length(aws_dynamodb_table.container_image_scans.global_secondary_index) == 0
    error_message = "Point-in-time recovery is paid and global secondary indexes use the shared free capacity"
  }
}
