variable "opentofu_encryption_passphrase" {
  description = "OpenTofu encryption passphrase"
  ephemeral   = true
  sensitive   = true
  type        = string
}
