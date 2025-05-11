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

resource "cloudflare_zero_trust_access_application" "uzg-01" {
  account_id = var.cloudflare_account_id

  name   = "uzg-01-2"
  domain = "uzg-01-2.xvx.cz"

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
  logo_url = "https://avatars.githubusercontent.com/u/5508130?v=4.png"
  tags     = ["iot", "lan"]
}

# Needs: Cloudflare Tunnel
# https://developers.cloudflare.com/api/resources/zero_trust/subresources/tunnels/
resource "cloudflare_zero_trust_tunnel_cloudflared" "gate" {
  account_id    = var.cloudflare_account_id
  name          = "gate-2"
  config_src    = "cloudflare"
  tunnel_secret = var.cloudflare_zero_trust_tunnel_cloudflared_tunnel_secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "gate" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.gate.id
  source     = "cloudflare"
  config = {
    ingress = [
      {
        hostname = "gate-2.xvx.cz"
        service  = "http://127.0.0.1"
      },
      {
        hostname = "gate-ssh-2.xvx.cz"
        service  = "ssh://127.0.0.1:22"
      },
      {
        hostname = "uzg-01-2.xvx.cz"
        service  = "http://192.168.1.3"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}
