# keep-sorted start block=yes newline_separated=yes
variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  sensitive   = true
  type        = string
}

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

variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  sensitive   = true
  type        = string
}
# keep-sorted end
