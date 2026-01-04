terraform {
  backend "s3" {
    bucket                      = "ruzickap-my-git-projects-opentofu-state-files"
    key                         = "ruzickap-my-git-projects-opentofu-cloudflare-github.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    use_lockfile                = true
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
  required_version = "~> 1.11"
  required_providers {
    # keep-sorted start block=yes
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.15.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.8"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 2.0"
    }
    uptimerobot = {
      source  = "uptimerobot/uptimerobot"
      version = "1.3.9"
    }
    # keep-sorted end
  }
}

# keep-sorted start block=yes newline_separated=yes
data "cloudflare_accounts" "all" {
  max_items = 1
}

# Fetch all API tokens from Cloudflare to find existing token by name
data "restapi_object" "cloudflare_tokens" {
  path         = "/accounts/${local.cloudflare_account_id}/tokens"
  results_key  = "result"
  id_attribute = "id"
  search_key   = "name"
  search_value = var.opentofu_cloudflare_github_api_token_name
}

locals {
  # keep-sorted start block=yes
  # Automatically get the first account ID from the API token's associated accounts
  cloudflare_account_id = data.cloudflare_accounts.all.result[0].id
  # Account email address used for notifications and ownership
  my_email = "petr.ruzicka@gmail.com"
  # Extract the token ID from the REST API response
  opentofu_cloudflare_github_api_token_id = data.restapi_object.cloudflare_tokens.id
  # keep-sorted end
}

provider "cloudflare" {
  api_token = var.opentofu_cloudflare_github_api_token
}

provider "github" {}

# REST API provider for fetching Cloudflare token ID by name
provider "restapi" {
  uri = "https://api.cloudflare.com/client/v4"
  headers = {
    Authorization = "Bearer ${var.opentofu_cloudflare_github_api_token}"
    Content-Type  = "application/json"
  }
  write_returns_object = true
}

provider "uptimerobot" {
  api_key = var.uptimerobot_api_key
}
# keep-sorted end
