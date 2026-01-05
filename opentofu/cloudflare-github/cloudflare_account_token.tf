# Fetch all available permission groups dynamically
data "cloudflare_account_api_token_permission_groups_list" "all" {
  account_id = local.cloudflare_account_id
}

locals {
  # All permission groups from the data source
  all_permission_groups = data.cloudflare_account_api_token_permission_groups_list.all.result

  # Account-scoped permissions map: name -> permission object
  account_permission_name_to_obj = {
    for p in local.all_permission_groups :
    p.name => p
    if length(p.scopes) > 0 && p.scopes[0] == "com.cloudflare.api.account"
  }

  # Zone-scoped permissions map: name -> permission object
  zone_permission_name_to_obj = {
    for p in local.all_permission_groups :
    p.name => p
    if length(p.scopes) > 0 && p.scopes[0] == "com.cloudflare.api.account.zone"
  }
}

################################################################################
# opentofu-cloudflare (ruzickap/my-git-projects/opentofu/cloudflare-github)
################################################################################

locals {
  # Account-scoped permissions
  account_permission_names = [
    # keep-sorted start
    "Access: Apps and Policies Write",
    "Access: Organizations, Identity Providers, and Groups Write",
    "Access: Service Tokens Write",
    "Account API Tokens Write", # create/manage API tokens via cloudflare_account_token
    "Account Settings Read",    # read account settings for cloudflare_web_analytics_site (https://developers.cloudflare.com/api/python/resources/rum/subresources/site_info/)
    "Account Settings Write",   # modify account settings and list accounts
    "Cloudflare Tunnel Write",
    "Email Routing Addresses Write",
    "Pages Write",
    "Workers R2 Storage Write", # access R2 buckets for OpenTofu state storage
    "Zero Trust Write",
    # keep-sorted end
  ]

  # Zone-scoped permissions
  zone_permission_names = [
    # keep-sorted start
    "DNS Write",
    "Dynamic URL Redirects Write", # manage dynamic redirect rules via cloudflare_ruleset
    "Zone Write",
    # keep-sorted end
  ]
}

# Import block for existing API token (automatically fetched by name)
import {
  to = cloudflare_account_token.opentofu_cloudflare_github
  id = "${local.cloudflare_account_id}/${local.opentofu_cloudflare_github_api_token_id}"
}

# Token for OpenTofu code in ruzickap/my-git-projects/opentofu/cloudflare-github
resource "cloudflare_account_token" "opentofu_cloudflare_github" {
  account_id = local.cloudflare_account_id
  name       = local.opentofu_cloudflare_github_api_token_name

  # Specific permissions based on requirements
  policies = [
    # Account-scoped permissions
    {
      effect = "allow"
      resources = jsonencode({
        "com.cloudflare.api.account.${local.cloudflare_account_id}" = "*"
      })
      permission_groups = [
        for name in local.account_permission_names :
        { id = local.account_permission_name_to_obj[name].id }
      ]
    },
    # Zone-scoped permissions (applies to all zones in the account)
    {
      effect = "allow"
      resources = jsonencode({
        "com.cloudflare.api.account.${local.cloudflare_account_id}" = "*"
      })
      permission_groups = [
        for name in local.zone_permission_names :
        { id = local.zone_permission_name_to_obj[name].id }
      ]
    },
  ]
}

output "cloudflare_account_token_opentofu_cloudflare_github" {
  description = "opentofu_cloudflare_github API Token details"
  sensitive   = true
  value = {
    OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN = data.sops_file.env_yaml.data["OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN"]
    CLOUDFLARE_R2_ACCESS_KEY_ID          = cloudflare_account_token.opentofu_cloudflare_github.id
    CLOUDFLARE_R2_SECRET_ACCESS_KEY      = sha256(data.sops_file.env_yaml.data["OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN"])
    CLOUDFLARE_R2_ENDPOINT_URL_S3        = "https://${local.cloudflare_account_id}.r2.cloudflarestorage.com"
  }
}

################################################################################
# cloudflare-account-token-pages-xvx-cz (ruzickap/xvx.cz)
# https://github.com/ruzickap/xvx.cz/blob/main/.github/workflows/gh-pages-build.yml
################################################################################
resource "cloudflare_account_token" "pages_xvx_cz" {
  account_id = local.cloudflare_account_id
  name       = "cloudflare-account-token-pages-xvx-cz (ruzickap/xvx.cz)"
  policies = [
    {
      effect = "allow"
      resources = jsonencode({
        "com.cloudflare.api.account.${local.cloudflare_account_id}" = "*"
      })
      permission_groups = [
        { id = local.account_permission_name_to_obj["Pages Write"].id },
      ]
    }
  ]
}

################################################################################
# cloudflare-account-token-pages-petr-ruzicka-dev (ruzickap/petr.ruzicka.dev)
# https://github.com/ruzickap/petr.ruzicka.dev/blob/main/.github/workflows/gh-pages-build.yml
################################################################################
resource "cloudflare_account_token" "pages_petr_ruzicka_dev" {
  account_id = local.cloudflare_account_id
  name       = "cloudflare-account-token-pages-petr-ruzicka-dev (ruzickap/petr.ruzicka.dev)"
  policies = [
    {
      effect = "allow"
      resources = jsonencode({
        "com.cloudflare.api.account.${local.cloudflare_account_id}" = "*"
      })
      permission_groups = [
        { id = local.account_permission_name_to_obj["Pages Write"].id },
      ]
    }
  ]
}

################################################################################
# cloudflare-account-token-pages-ruzickap-github-io (ruzickap/ruzickap.github.io)
# https://github.com/ruzickap/ruzickap.github.io/blob/main/.github/workflows/gh-pages-build.yml
################################################################################
resource "cloudflare_account_token" "pages_ruzickap_github_io" {
  account_id = local.cloudflare_account_id
  name       = "cloudflare-account-token-pages-ruzickap-github-io (ruzickap/ruzickap.github.io)"
  policies = [
    {
      effect = "allow"
      resources = jsonencode({
        "com.cloudflare.api.account.${local.cloudflare_account_id}" = "*"
      })
      permission_groups = [
        { id = local.account_permission_name_to_obj["Pages Write"].id },
      ]
    }
  ]
}
