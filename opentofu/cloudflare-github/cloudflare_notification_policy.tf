locals {
  notification_policies = {
    abuse_report = {
      alert_type  = "abuse_report_alert"
      name        = "Cloudflare Abuse Report Alert"
      description = "Get notifications when Cloudflare receives an abuse report regarding your domain"
    }
    expiring_access_service_token = {
      alert_type  = "expiring_service_token_alert"
      name        = "Expiring Access Service Token Alert"
      description = "Cloudflare Access service token expiration notice, sent 7 days before token expires"
    }
    passive_origin_monitoring = {
      alert_type  = "real_origin_monitoring"
      name        = "Passive Origin Monitoring"
      description = "Cloudflare is unable to reach your origin"
    }
    web_analytics = {
      alert_type  = "web_analytics_metrics_update"
      name        = "Web Analytics Metrics Update"
      description = "Receive regular Web Analytics metrics updates by email"
    }
  }
}

resource "cloudflare_notification_policy" "this" {
  for_each    = local.notification_policies
  account_id  = local.cloudflare_account_id
  alert_type  = each.value.alert_type
  name        = each.value.name
  description = each.value.description
  mechanisms = {
    email = [{
      id = local.my_email
    }]
  }
}

# Cloudflare Status: Cloudflare is experiencing a critical incident
resource "cloudflare_notification_policy" "incident" {
  account_id  = local.cloudflare_account_id
  alert_type  = "incident_alert"
  name        = "Incident Alert"
  description = "Cloudflare is experiencing a critical incident"
  mechanisms = {
    email = [{
      id = local.my_email
    }]
  }
  filters = {
    incident_impact = ["INCIDENT_IMPACT_MAJOR"]
  }
}

# Billing: Billing usage exceeds your configured threshold for a specific product
# Available products depend on your account: R2 Storage, R2 Storage Class A/B Operations
resource "cloudflare_notification_policy" "billing_usage" {
  account_id  = local.cloudflare_account_id
  alert_type  = "billing_usage_alert"
  name        = "Usage Based Billing"
  description = "Alert when R2 Storage usage exceeds 100 MB"
  mechanisms = {
    email = [{
      id = local.my_email
    }]
  }
  filters = {
    limit   = ["104857600"] # 100 MB in bytes
    product = ["r2_storage"]
  }
}

# Tunnel Health: Receive an alert for the health of a Tunnel
resource "cloudflare_notification_policy" "tunnel_health" {
  account_id  = local.cloudflare_account_id
  alert_type  = "tunnel_health_event"
  name        = "Tunnel Health Alert"
  description = "Receive an alert when tunnel becomes degraded or down"
  mechanisms = {
    email = [{
      id = local.my_email
    }]
  }
  filters = {
    tunnel_id = [
      cloudflare_zero_trust_tunnel_cloudflared.tunnels["gate"].id,
      # RPi is too noisy due to weak WiFi signal
      # cloudflare_zero_trust_tunnel_cloudflared.tunnels["raspi"].id,
    ]
    new_status = [
      "TUNNEL_STATUS_TYPE_DEGRADED",
      "TUNNEL_STATUS_TYPE_DOWN",
    ]
  }
}
