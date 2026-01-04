# keep-sorted start block=yes newline_separated=yes
variable "cloudflare_zero_trust_access_identity_provider_google_oauth_client_id" {
  description = "Cloudflare Zero Trust Access Identity Provider - Google OAuth Client ID"
  sensitive   = true
  type        = string
}

variable "cloudflare_zero_trust_access_identity_provider_google_oauth_client_secret" {
  description = "Cloudflare Zero Trust Access Identity Provider - Google OAuth Client Secret"
  sensitive   = true
  type        = string
}

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

variable "opentofu_cloudflare_github_api_token" {
  description = "Cloudflare API token with Account:API Tokens:Edit permission"
  type        = string
  sensitive   = true
}

variable "opentofu_cloudflare_github_api_token_name" {
  description = "Name of the Cloudflare API token to manage"
  type        = string
  default     = "opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)"
}

variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  sensitive   = true
  type        = string
}

variable "uptimerobot_api_key" {
  description = "UptimeRobot API Key"
  sensitive   = true
  type        = string
}
# keep-sorted end
