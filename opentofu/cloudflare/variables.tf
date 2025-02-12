variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  sensitive   = true
  type        = string
}

variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  sensitive   = true
  type        = string
}
