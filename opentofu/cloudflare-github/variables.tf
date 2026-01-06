variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  sensitive   = true
  type        = string
}

variable "gh_token_opentofu_cloudflare_github" {
  description = "GitHub personal access token for managing Cloudflare and GitHub resources"
  sensitive   = true
  type        = string
}
