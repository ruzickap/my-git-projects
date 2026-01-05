locals {
  uptimerobot_ips_url = "https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt"
  uptimerobot_ips     = [for item in distinct(compact(split("\n", data.http.my_file.response_body))) : { "value" = item, "description" = "Dallas-USA" }]
  tags                = ["container", "iot", "lan", "router", "rpi", "wan", "wifi"]
  allowed_emails = [
    {
      email = {
        email = local.my_email
      }
    }
  ]
  cloudflare_zero_trust_tunnels_applications = {
    # keep-sorted start block=yes
    "gate" = {
      applications = {
        # keep-sorted start block=yes
        "gate" = {
          logo_url = "https://raw.githubusercontent.com/openwrt/branding/master/logo/openwrt_logo_blue_and_dark_blue.png"
          service  = "https://127.0.0.1"
          tags     = ["lan", "router", "wan"]
        }
        "gate-ssh" = {
          service = "ssh://127.0.0.1:22"
          tags    = ["lan", "router", "ssh", "wan"]
        }
        "msr-2" = {
          logo_url = "https://raw.githubusercontent.com/ApolloAutomation/docs/7c110c74481441d464acffb3785c5e6c75230944/docs/assets/favicon.png"
          service  = "http://192.168.1.4"
          tags     = ["iot", "wifi"]
        }
        "transmission" = {
          logo_url = "https://raw.githubusercontent.com/transmission/transmission-icons/2ede5e3fa6a3cc1bd21c68c629b43221a91c314b/Transmission.png"
          service  = "http://127.0.0.1:9091"
          tags     = ["router"]
        }
        "uzg-01" = {
          logo_url = "https://avatars.githubusercontent.com/u/5508130?v=4.png"
          service  = "http://192.168.1.3"
          tags     = ["iot", "lan"]
        }
        # keep-sorted end
      }
    },
    "raspi" = {
      applications = {
        # keep-sorted start block=yes
        "alloy-rpi" = {
          logo_url = "https://raw.githubusercontent.com/grafana/alloy/9b878da08fec0467a88637fd26e5be6da2037574/internal/web/ui/src/images/logo.svg"
          service  = "http://localhost:12345"
          tags     = ["rpi", "wifi"]
        }
        "esphome-rpi" = {
          logo_url = "https://raw.githubusercontent.com/esphome/esphome-docs/e28345cd8f1c9380bc25dd977fcf443ba5c8612c/images/logo.svg"
          service  = "http://localhost:6052"
          tags     = ["container", "iot", "rpi", "wifi"]
        }
        "grafana-rpi" = {
          logo_url = "https://raw.githubusercontent.com/walkxcode/dashboard-icons/59fb4c9e102455073d6068b6533d4c77aed724fc/svg/grafana.svg"
          service  = "http://localhost:3001"
          tags     = ["rpi", "wifi"]
        }
        "hass-rpi" = {
          logo_url = "https://upload.wikimedia.org/wikipedia/commons/6/6e/Home_Assistant_Logo.svg"
          policies = [
            {
              id         = cloudflare_zero_trust_access_policy.allow_all.id
              precedence = 1
            }
          ]
          service = "http://localhost:8123"
          tags    = ["container", "iot", "rpi", "wifi"]
        }
        "kodi-rpi" = {
          logo_url = "https://upload.wikimedia.org/wikipedia/commons/0/00/Kodi-top-bottom.svg"
          service  = "http://localhost:8080"
          tags     = ["rpi", "wifi"]
        }
        "prometheus-rpi" = {
          logo_url = "https://raw.githubusercontent.com/cncf/artwork/c33a8386bce4eabc36e1d4972e0996db4630037b/projects/prometheus/icon/color/prometheus-icon-color.svg"
          service  = "http://localhost:9090"
          tags     = ["rpi", "wifi"]
        }
        "rpi" = {
          logo_url = "https://upload.wikimedia.org/wikipedia/en/c/cb/Raspberry_Pi_Logo.svg"
          service  = "http://127.0.0.1:3000"
          tags     = ["container", "rpi", "wifi"]
        }
        "rpi-ssh" = {
          service = "ssh://127.0.0.1:22"
          tags    = ["rpi", "ssh", "wifi"]
        }
        "zigbee2mqtt-rpi" = {
          logo_url = "https://raw.githubusercontent.com/Koenkk/zigbee2mqtt/9c505fd75f503a91a61244d6f0efa0e37d81a7b0/images/logo_vector.svg"
          service  = "http://localhost:8082"
          tags     = ["container", "iot", "rpi", "wifi"]
        }
        # keep-sorted end
      }
    }
    # keep-sorted end
  }
}

data "http" "my_file" {
  url = local.uptimerobot_ips_url
}

# Needs: Access: Organizations, Identity Providers, and Groups
# https://developers.cloudflare.com/api/python/resources/zero_trust/subresources/identity_providers/methods/create/
resource "cloudflare_zero_trust_access_identity_provider" "google_oauth" {
  name       = "Google IDP"
  type       = "google"
  account_id = local.cloudflare_account_id
  config = {
    client_id     = data.sops_file.env_yaml.data["cloudflare_zero_trust_access_identity_provider_google_oauth_client_id"]
    client_secret = data.sops_file.env_yaml.data["cloudflare_zero_trust_access_identity_provider_google_oauth_client_secret"]
  }
}

resource "cloudflare_zero_trust_access_policy" "google_sso_access" {
  account_id = local.cloudflare_account_id
  name       = "Google SSO Access"
  decision   = "allow"
  include    = local.allowed_emails
}

# Needs: Zero Trust
resource "cloudflare_zero_trust_list" "uptimerobot_ips" {
  account_id  = local.cloudflare_account_id
  name        = "UptimeRobot IPs"
  type        = "IP"
  description = "UptimeRobot IP addresses of their checks (https://uptimerobot.com/help/locations/)"
  items       = local.uptimerobot_ips
}

resource "cloudflare_zero_trust_access_tag" "tags" {
  account_id = local.cloudflare_account_id
  for_each   = toset(local.tags)
  name       = each.key
}

resource "cloudflare_zero_trust_access_policy" "uptimerobot_direct_access" {
  account_id = local.cloudflare_account_id
  name       = "UptimeRobot Direct Access"
  decision   = "bypass"
  include = [{
    ip_list = {
      id = cloudflare_zero_trust_list.uptimerobot_ips.id
    }
  }]
}

resource "cloudflare_zero_trust_access_policy" "allow_all" {
  account_id = local.cloudflare_account_id
  name       = "Allow All"
  decision   = "bypass"
  include    = [{ everyone = {} }]
}

###############################################
# Cloudflare Tunnels
###############################################
# Needs: Cloudflare Tunnel
# https://developers.cloudflare.com/api/resources/zero_trust/subresources/tunnels/

# Create cloudflare_zero_trust_tunnel_cloudflared resources for each tunnel in the map
resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnels" {
  for_each   = local.cloudflare_zero_trust_tunnels_applications
  account_id = local.cloudflare_account_id
  name       = each.key
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "configs" {
  for_each   = local.cloudflare_zero_trust_tunnels_applications
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnels[each.key].id
  source     = "cloudflare"
  config = {
    ingress = concat(
      [
        for app_name, app in each.value.applications : {
          hostname = "${app_name}.${cloudflare_zone.xvx_cz.name}"
          service  = app.service
          origin_request = {
            no_tls_verify = true
          }
        }
      ],
      [
        {
          service = "http_status:404"
        }
      ]
    )
  }
}

resource "cloudflare_zero_trust_access_application" "applications" {
  for_each = {
    for app_name, app in merge([for tunnel in local.cloudflare_zero_trust_tunnels_applications : tunnel.applications]...) :
    app_name => app if !startswith(app.service, "ssh://")
  }

  account_id = local.cloudflare_account_id

  name                      = each.key
  domain                    = "${each.key}.${cloudflare_zone.xvx_cz.name}"
  type                      = "self_hosted"
  allowed_idps              = [cloudflare_zero_trust_access_identity_provider.google_oauth.id]
  auto_redirect_to_identity = true

  logo_url = each.value.logo_url
  tags     = each.value.tags

  # Use policies from the app if defined, otherwise default to Google SSO and UptimeRobot
  policies = try(
    each.value.policies,
    [
      {
        id         = cloudflare_zero_trust_access_policy.uptimerobot_direct_access.id
        precedence = 1
      },
      {
        id         = cloudflare_zero_trust_access_policy.google_sso_access.id
        precedence = 2
      }
    ]
  )
}
