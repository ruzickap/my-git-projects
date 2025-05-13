resource "cloudflare_zone" "xvx_cz" {
  account = {
    id = var.cloudflare_account_id
  }
  name = "xvx.cz"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

# keep-sorted start block=yes newline_separated=yes
resource "cloudflare_dns_record" "a_gate_bracha_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Gate/Router Bracha in Zebetin"
  content = "176.74.157.134"
  name    = "gate-bracha.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "A"
}

resource "cloudflare_dns_record" "a_raspi_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "RPi [192.168.1.2] in my home network"
  content = "192.168.1.2"
  name    = "raspi.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "A"
}

resource "cloudflare_dns_record" "a_stats_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Used for redirection to https://stats.uptimerobot.com/AOziwZJXwt"
  content = "192.0.2.1"
  name    = "stats.${cloudflare_zone.xvx_cz.name}"
  proxied = true
  ttl     = 1
  type    = "A"
}

resource "cloudflare_dns_record" "cname_byt_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for https://bytvujezdech1.blogspot.com"
  content = "ghs.google.com"
  name    = "byt.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_cestovani_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "ghs.google.com"
  name    = "cestovani.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_linux_old_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for GitHub Pages: https://github.com/ruzickap/linux.xvx.cz"
  content = "ruzickap.github.io"
  name    = "linux-old.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_linux_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for https://linux-xvx-cz.blogspot.com"
  content = "ghs.google.com"
  name    = "linux.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_petr_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for GitHub Pages: https://github.com/ruzickap/petr.xvx.cz | https://petr.ruzicka.dev/"
  content = "ruzickap.github.io"
  name    = "petr.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_ruzickovabozena_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for GitHub Pages: https://github.com/ruzickap/ruzickovabozena.xvx.cz"
  content = "ruzickap.github.io"
  name    = "ruzickovabozena.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_svatba_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for GitHub Pages: https://github.com/ruzickap/svatba.xvx.cz"
  content = "ruzickap.github.io"
  name    = "svatba.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_linux_old_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "ruzickap.github.io"
  name    = "www.linux-old.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_linux_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "linux.xvx.cz"
  name    = "www.linux.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_ruzickovabozena_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "ruzickap.github.io"
  name    = "www.ruzickovabozena.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_svatba_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "ruzickap.github.io"
  name    = "www.svatba.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "ruzickap.github.io"
  name    = "www.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Redirection for GitHub Pages: https://github.com/ruzickap/xvx.cz"
  content = "ruzickap.github.io"
  name    = cloudflare_zone.xvx_cz.name
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_zero_trust_tunnel" {
  for_each = {
    for record in flatten([
      for tunnel_name, tunnel in cloudflare_zero_trust_tunnel_cloudflared_config.configs :
      [
        for ingress in tunnel.config.ingress :
        {
          tunnel_id   = tunnel.id
          tunnel_name = tunnel_name
          hostname    = ingress.hostname
          service     = ingress.service
        }
        if ingress.hostname != null && ingress.hostname != ""
      ]
    ]) : record.hostname => record
  }

  zone_id = cloudflare_zone.xvx_cz.id
  comment = "Cloudflare tunnel record for ${each.value.tunnel_name} - ${each.key} - ${each.value.service}"
  content = "${each.value.tunnel_id}.cfargotunnel.com"
  name    = each.key
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "mx1_xvx_cz" {
  zone_id  = cloudflare_zone.xvx_cz.id
  content  = "aspmx.l.google.com"
  name     = cloudflare_zone.xvx_cz.name
  priority = 5
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx2_xvx_cz" {
  zone_id  = cloudflare_zone.xvx_cz.id
  content  = "alt1.aspmx.l.google.com"
  name     = cloudflare_zone.xvx_cz.name
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx3_xvx_cz" {
  zone_id  = cloudflare_zone.xvx_cz.id
  content  = "alt2.aspmx.l.google.com"
  name     = cloudflare_zone.xvx_cz.name
  priority = 20
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx4_xvx_cz" {
  zone_id  = cloudflare_zone.xvx_cz.id
  content  = "alt3.aspmx.l.google.com"
  name     = cloudflare_zone.xvx_cz.name
  priority = 30
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx5_xvx_cz" {
  zone_id  = cloudflare_zone.xvx_cz.id
  content  = "alt4.aspmx.l.google.com"
  name     = cloudflare_zone.xvx_cz.name
  priority = 40
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "txt_acme_challenge_auth_infra_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "_d-VJBZ8HF6-jVDYxoLZbWtNVksym1psIOjvijxdWUw"
  name    = "_acme-challenge.auth.infra.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 120
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_dkim1_google_domainkey_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA9lBTbndSVB2mw8nw8OjorEvroT0hEAsWdK3n5reYepnMx8EROpq4vd3uzM2xjyzxqx80xdiQ1Hz/tHiB1fv8i2sO1LzvHhjIkEKkPqzC6D0YV/+79Lm3+Sf7bci916JAibHA3ejWVdAGvbspuvcvELPr2aeTkVvPOei4Y+8/jjGzQvU1LIHIa86FJh9iFJIJec5Kme2ghhuOHOQpboi06gM58TrF8GC8NPv22n1qcMp6HLccl3qfkY15w88xw118KjCZRHnXecsxFCyGY7mDwsufRqbprixvDqq3+vG7Gb1LIbWP9DS0aWaHxRDSTq3H5+Bnm4mDQHA2BkC1ZrKxMQIDAQAB"
  name    = "google._domainkey.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_dmarc1_dmarc_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "\"v=DMARC1; p=none; rua=mailto:petr.ruzicka@gmail.com\""
  name    = "_dmarc.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_google_site_verification_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "google-site-verification=S7LT5KvxFLKml7e8cM5W5_4Ndf2HxhLcCKPTd2If2d8"
  name    = cloudflare_zone.xvx_cz.name
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_spf1_xvx_cz" {
  zone_id = cloudflare_zone.xvx_cz.id
  content = "v=spf1 include:_spf.google.com ~all"
  name    = cloudflare_zone.xvx_cz.name
  proxied = false
  ttl     = 1
  type    = "TXT"
}

# # Needs: ????
# # https://developers.cloudflare.com/api/resources/rulesets/
# resource "cloudflare_ruleset" "status_xvx_cz" {
#   zone_id     = cloudflare_zone.xvx_cz.id
#   name        = "status.xvx.cz"
#   description = "Redirect to https://stats.uptimerobot.com/AOziwZJXwt"
#   kind        = "zone"
#   phase       = "http_request_dynamic_redirect"
#   rules = [{
#     action = "redirect"
#     action_parameters = {
#       from_value = {
#         status_code = 301
#         target_url = {
#           value = "https://stats.uptimerobot.com/AOziwZJXwt"
#         }
#       }
#     }
#     expression  = "(http.host eq \"status.xvx.cz\")"
#     description = "status.xvx.cz"
#     enabled     = false
#   }]
# }
# keep-sorted end
