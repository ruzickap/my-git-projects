locals {
  uptimerobot_ips_url = "https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt"
  uptimerobot_ips     = [for item in distinct(compact(split("\n", data.http.my_file.response_body))) : { "value" = item, "description" = "Dallas-USA" }]
  tags                = ["iot", "lan", "wifi"]
  allowed_emails = [
    {
      email = {
        email = "petr.ruzicka@gmail.com"
      }
    }
  ]
}

data "http" "my_file" {
  url = local.uptimerobot_ips_url
}

# Needs: Access: Organizations, Identity Providers, and Groups
# https://developers.cloudflare.com/api/python/resources/zero_trust/subresources/identity_providers/methods/create/
resource "cloudflare_zero_trust_access_identity_provider" "google_oauth" {
  name       = "My Test Google IDP - 2"
  type       = "google"
  account_id = var.cloudflare_account_id
  config = {
    client_id     = var.cloudflare_zero_trust_access_identity_provider_google_oauth_client_id
    client_secret = var.cloudflare_zero_trust_access_identity_provider_google_oauth_client_secret
  }
}

resource "cloudflare_zero_trust_access_policy" "google_sso_access" {
  account_id = var.cloudflare_account_id
  name       = "Google SSO Access - 2"
  decision   = "allow"
  include    = local.allowed_emails
}

# Needs: Zero Trust
resource "cloudflare_zero_trust_list" "uptimerobot_ips" {
  account_id  = var.cloudflare_account_id
  name        = "UptimeRobot IPs-2"
  type        = "IP"
  description = "UptimeRobot IP addresses of their checks (https://uptimerobot.com/help/locations/)"
  items       = local.uptimerobot_ips
}

resource "cloudflare_zero_trust_access_tag" "tags" {
  account_id = var.cloudflare_account_id
  for_each   = toset(local.tags)
  name       = each.key
}

resource "cloudflare_zero_trust_access_policy" "uptimerobot_direct_access" {
  account_id = var.cloudflare_account_id
  name       = "UptimeRobot Direct Access - 2"
  decision   = "bypass"
  include = [{
    ip_list = {
      id = cloudflare_zero_trust_list.uptimerobot_ips.id
    }
  }]
}

resource "cloudflare_zero_trust_access_application" "msr_2" {
  account_id = var.cloudflare_account_id

  name   = "msr-2-2"
  domain = "msr-2-2.mylabs.dev"

  type = "self_hosted"
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.uptimerobot_direct_access.id
      precedence = 1
    },
    {
      id         = cloudflare_zero_trust_access_policy.google_sso_access.id
      precedence = 2
    },
  ]
  logo_url = "https://raw.githubusercontent.com/ApolloAutomation/docs/7c110c74481441d464acffb3785c5e6c75230944/docs/assets/favicon.png"
  tags     = ["iot", "wifi"]
}

# Needs: Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "gate" {
  account_id    = var.cloudflare_account_id
  name          = "gate-2"
  config_src    = "cloudflare"
  tunnel_secret = var.cloudflare_zero_trust_tunnel_cloudflared_tunnel_secret
}

# Needs: Cloudflare Tunnel
# https://developers.cloudflare.com/api/resources/zero_trust/subresources/tunnels/
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "gate" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gate.id
  source     = "cloudflare"
  config = {
    ingress = [
      {
        hostname = "gate-2.mylabs.dev"
        service  = "tcp://localhost:6379"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
