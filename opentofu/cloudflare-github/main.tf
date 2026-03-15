terraform {
  backend "s3" {
    bucket       = "ruzickap-my-git-projects-opentofu-state-files"
    key          = "ruzickap-my-git-projects-opentofu-cloudflare-github.tfstate"
    use_lockfile = true
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
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 3"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1"
    }
    uptimerobot = {
      source  = "uptimerobot/uptimerobot"
      version = "~> 1"
    }
    # keep-sorted end
  }
}

# keep-sorted start block=yes newline_separated=yes
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "cloudflare_accounts" "all" {
  max_items = 1
}

# Fetch all API tokens from Cloudflare to find existing token by name
data "restapi_object" "cloudflare_tokens" {
  path         = "/accounts/${local.cloudflare_account_id}/tokens"
  results_key  = "result"
  id_attribute = "id"
  search_key   = "name"
  search_value = local.opentofu_cloudflare_github_api_token_name
}

locals {
  # keep-sorted start
  # Automatically get the first account ID from the API token's associated accounts
  cloudflare_account_id = data.cloudflare_accounts.all.result[0].id
  # Account email address used for notifications and ownership
  my_email = "petr.ruzicka@gmail.com"
  # Extract the token ID from the REST API response
  opentofu_cloudflare_github_api_token_id = data.restapi_object.cloudflare_tokens.id
  # Name of the Cloudflare API token to manage
  opentofu_cloudflare_github_api_token_name = "opentofu-cloudflare-github (ruzickap/my-git-projects/opentofu/cloudflare-github)"
  # ARN prefix for SSM parameters — used by ephemeral resources which require ARN instead of name (https://github.com/hashicorp/terraform-provider-aws/issues/40623)
  ssm_parameter_arn_prefix = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter"
  # keep-sorted end
}

provider "aws" {
  default_tags {
    tags = {
      managed-by = "opentofu"
      owner      = local.my_email
      repository = "ruzickap/my-git-projects/opentofu/cloudflare-github"
    }
  }
}

provider "cloudflare" {
  api_token = ephemeral.aws_ssm_parameter.github_ruzickap_my_git_projects_actions_secrets_opentofu_cloudflare_github_api_token.value
}

provider "github" {
  token = ephemeral.aws_ssm_parameter.github_ruzickap_my_git_projects_actions_secrets_gh_token_opentofu_cloudflare_github.value
}

# REST API provider for fetching Cloudflare token ID by name
provider "restapi" {
  uri = "https://api.cloudflare.com/client/v4"
  headers = {
    Authorization = "Bearer ${ephemeral.aws_ssm_parameter.github_ruzickap_my_git_projects_actions_secrets_opentofu_cloudflare_github_api_token.value}"
    Content-Type  = "application/json"
  }
  write_returns_object = true
}

provider "supabase" {
  access_token = data.aws_ssm_parameter.github_ruzickap_container_image_scans_actions_secrets_SUPABASE_ACCESS_TOKEN.value
}

provider "uptimerobot" {
  api_key = ephemeral.aws_ssm_parameter.github_ruzickap_my_git_projects_actions_secrets_uptimerobot_api_key.value
}
# keep-sorted end
