# keep-sorted start block=yes newline_separated=yes
variable "my_renovate_github_app_id" {
  description = "My Renovate GitHub Application app id"
  sensitive   = true
  type        = string
}

variable "my_renovate_github_private_key" {
  description = "My Renovate GitHub Application private key"
  sensitive   = true
  type        = string
}

variable "my_slack_bot_token" {
  description = "My Slack bot token"
  sensitive   = true
  type        = string
}

variable "my_slack_channel_id" {
  description = "My Slack channel id"
  sensitive   = true
  type        = string
}

variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  sensitive   = true
  type        = string
}

# keep-sorted end
