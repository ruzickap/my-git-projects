locals {
  # Domain monitoring for all zones
  monitored_domains = merge(
    # xvx.cz CNAME records (publicly accessible GitHub Pages and services)
    {
      for key, record in local.xvx_cz_cname_records :
      key == "" ? "xvx_cz" : "${key}_xvx_cz" => {
        domain = key == "" ? cloudflare_zone.xvx_cz.name : "${key}.${cloudflare_zone.xvx_cz.name}"
        tags   = ["xvx_cz"]
      }
      if !startswith(key, "www.") && key != "www.linux" # Exclude www subdomains to avoid duplicates
    },
    # xvx.cz A records (only proxied ones that are publicly accessible)
    {
      for key, record in local.xvx_cz_a_records :
      "${key}_a_xvx_cz" => {
        domain = "${key}.${cloudflare_zone.xvx_cz.name}"
        tags   = ["xvx_cz"]
      }
      if record.proxied
    },
    # ruzicka.dev CNAME records (personal blog and pages)
    {
      for key, record in local.ruzicka_dev_cname_records :
      key == "" ? "ruzicka_dev" : "${key}_ruzicka_dev" => {
        domain = key == "" ? cloudflare_zone.ruzicka_dev.name : "${key}.${cloudflare_zone.ruzicka_dev.name}"
        tags   = ["ruzicka_dev"]
      }
      if key != "www" # Exclude www to avoid duplicate of root domain
    },
    # mylabs.dev CNAME records (main domain only, exclude mailtrap/technical records)
    {
      for key, record in local.mylabs_dev_cname_records :
      key == "" ? "mylabs_dev" : "${key}_mylabs_dev" => {
        domain = key == "" ? cloudflare_zone.mylabs_dev.name : "${key}.${cloudflare_zone.mylabs_dev.name}"
        tags   = ["mylabs_dev"]
      }
      if key == "" || key == "www" # Only monitor main domain and www
    }
  )
}

# Monitor Zero Trust tunnel applications
resource "uptimerobot_monitor" "zero_trust_applications" {
  for_each = {
    for app_name, app in merge([for tunnel in local.cloudflare_zero_trust_tunnels_applications : tunnel.applications]...) :
    app_name => app if !startswith(app.service, "ssh://")
  }

  name     = "${each.key}.${cloudflare_zone.xvx_cz.name}"
  type     = "HTTP"
  url      = "https://${each.key}.${cloudflare_zone.xvx_cz.name}"
  interval = 300

  tags = each.value.tags
}

# Monitor all domains from zones
resource "uptimerobot_monitor" "domain_monitors" {
  for_each = local.monitored_domains

  name     = each.value.domain
  type     = "HTTP"
  url      = "https://${each.value.domain}"
  interval = 300

  tags = each.value.tags
}

# Public Status Page for all monitored services
resource "uptimerobot_psp" "all_services" {
  name = "My Services Status"

  # Include all monitors: Zero Trust applications + All monitored domains
  monitor_ids = concat(
    [for monitor in uptimerobot_monitor.zero_trust_applications : monitor.id],
    [for monitor in uptimerobot_monitor.domain_monitors : monitor.id]
  )
}
