terraform {
  backend "s3" {
    bucket                      = "ruzickap-my-git-projects-opentofu-state-file"
    key                         = "ruzickap-my-git-projects-opentofu-cloudflare.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
  }
  encryption {
    key_provider "pbkdf2" "mykey" {
      passphrase = var.opentofu_encryption_passphrase
    }
    method "aes_gcm" "new_method" {
      keys = key_provider.pbkdf2.mykey
    }
    state {
      method   = method.aes_gcm.new_method
      enforced = true
    }
  }
  required_version = "~> 1.9"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.8.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3"
    }
    uptimerobot = {
      source  = "uptimerobot/uptimerobot"
      version = "1.1.0"
    }
  }
}

provider "cloudflare" {}

provider "uptimerobot" {
  api_key = var.uptimerobot_api_key
}
