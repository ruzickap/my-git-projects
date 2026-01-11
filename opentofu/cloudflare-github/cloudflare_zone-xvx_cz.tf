locals {
  # keep-sorted start block=yes newline_separated=yes
  # A Records for xvx.cz
  xvx_cz_a_records = {
    # keep-sorted start block=yes
    "gate-bracha" = {
      content = "176.74.157.134"
      comment = "Gate/Router Bracha in Zebetin"
      proxied = false
    }
    "raspi" = {
      content = "192.168.1.2"
      comment = "RPi [192.168.1.2] in my home network"
      proxied = false
    }
    "stats" = {
      content = "192.0.2.1"
      comment = "Used for redirection to https://stats.uptimerobot.com/AOziwZJXwt"
      proxied = true
    }
    # keep-sorted end
  }

  # CNAME Records for xvx.cz
  xvx_cz_cname_records = {
    # keep-sorted start block=yes
    "" = {
      content                    = "ruzickap.github.io"
      comment                    = "Redirection for GitHub Pages: https://github.com/ruzickap/xvx.cz"
      observatory_scheduled_test = true
    }
    "byt" = {
      content                    = "ghs.google.com"
      comment                    = "Redirection for https://bytvujezdech1.blogspot.com"
      observatory_scheduled_test = true
    }
    "cestovani" = {
      content = "ghs.google.com"
      comment = "Cestování"
    }
    "linux" = {
      content                    = "ghs.google.com"
      comment                    = "Redirection for https://linux-xvx-cz.blogspot.com"
      observatory_scheduled_test = true
    }
    "linux-old" = {
      content = "ruzickap.github.io"
      comment = "Redirection for GitHub Pages: https://github.com/ruzickap/linux.xvx.cz"
    }
    "petr" = {
      content = "ruzickap.github.io"
      comment = "Redirection for GitHub Pages: https://github.com/ruzickap/petr.xvx.cz | https://petr.ruzicka.dev/"
    }
    "ruzickovabozena" = {
      content = "ruzickap.github.io"
      comment = "Redirection for GitHub Pages: https://github.com/ruzickap/ruzickovabozena.xvx.cz"
    }
    "svatba" = {
      content = "ruzickap.github.io"
      comment = "Redirection for GitHub Pages: https://github.com/ruzickap/svatba.xvx.cz"
    }
    "www" = {
      content = "ruzickap.github.io"
      comment = "Main Page"
    }
    "www.linux" = {
      content = "linux.xvx.cz"
      comment = "Petr's blog about Linux"
    }
    "www.linux-old" = {
      content = "ruzickap.github.io"
      comment = "Redirection for GitHub Pages: https://github.com/ruzickap/linux.xvx.cz"
    }
    "www.ruzickovabozena" = {
      content = "ruzickap.github.io"
      comment = "Božena Růžičková - Profesní webové stránky"
    }
    "www.svatba" = {
      content = "ruzickap.github.io"
      comment = "Svatba: Andrea a Petr"
    }
    # keep-sorted end
  }

  # MX Records for xvx.cz
  xvx_cz_mx_records = {
    # keep-sorted start block=yes
    "mx1" = {
      content  = "aspmx.l.google.com"
      priority = 5
    }
    "mx2" = {
      content  = "alt1.aspmx.l.google.com"
      priority = 10
    }
    "mx3" = {
      content  = "alt2.aspmx.l.google.com"
      priority = 20
    }
    "mx4" = {
      content  = "alt3.aspmx.l.google.com"
      priority = 30
    }
    "mx5" = {
      content  = "alt4.aspmx.l.google.com"
      priority = 40
    }
    # keep-sorted end
  }

  # TXT Records for xvx.cz
  xvx_cz_txt_records = {
    # keep-sorted start block=yes
    "_acme-challenge.auth.infra" = {
      content = "_d-VJBZ8HF6-jVDYxoLZbWtNVksym1psIOjvijxdWUw"
      ttl     = 120
      name    = "_acme-challenge.auth.infra"
    }
    "_dmarc" = {
      content = "\"v=DMARC1; p=none; rua=mailto:petr.ruzicka@gmail.com\""
      ttl     = 1
      name    = "_dmarc"
    }
    "google-site-verification" = {
      content = "google-site-verification=S7LT5KvxFLKml7e8cM5W5_4Ndf2HxhLcCKPTd2If2d8"
      ttl     = 1
      name    = ""
    }
    "google._domainkey" = {
      content = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA9lBTbndSVB2mw8nw8OjorEvroT0hEAsWdK3n5reYepnMx8EROpq4vd3uzM2xjyzxqx80xdiQ1Hz/tHiB1fv8i2sO1LzvHhjIkEKkPqzC6D0YV/+79Lm3+Sf7bci916JAibHA3ejWVdAGvbspuvcvELPr2aeTkVvPOei4Y+8/jjGzQvU1LIHIa86FJh9iFJIJec5Kme2ghhuOHOQpboi06gM58TrF8GC8NPv22n1qcMp6HLccl3qfkY15w88xw118KjCZRHnXecsxFCyGY7mDwsufRqbprixvDqq3+vG7Gb1LIbWP9DS0aWaHxRDSTq3H5+Bnm4mDQHA2BkC1ZrKxMQIDAQAB"
      ttl     = 1
      name    = "google._domainkey"
    }
    "spf" = {
      content = "v=spf1 include:_spf.google.com ~all"
      ttl     = 1
      name    = ""
    }
    # keep-sorted end
  }
  # keep-sorted end
}

# Zone for xvx.cz
resource "cloudflare_zone" "xvx_cz" {
  account = {
    id = local.cloudflare_account_id
  }
  name = "xvx.cz"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_dnssec" "example_zone_dnssec" {
  zone_id = cloudflare_zone.xvx_cz.id
  status  = "active"
}

resource "cloudflare_zone_setting" "xvx_cz_min_tls_version" {
  zone_id    = cloudflare_zone.xvx_cz.id
  setting_id = "min_tls_version"
  value      = "1.3"
}

resource "cloudflare_observatory_scheduled_test" "xvx_cz" {
  for_each = { for k, v in local.xvx_cz_cname_records : k => v if try(v.observatory_scheduled_test, false) }
  zone_id  = cloudflare_zone.xvx_cz.id
  url      = each.key == "" ? "xvx.cz" : "${each.key}.xvx.cz"
}

# A Records for xvx.cz
resource "cloudflare_dns_record" "xvx_cz_a_records" {
  for_each = local.xvx_cz_a_records

  zone_id = cloudflare_zone.xvx_cz.id
  comment = each.value.comment
  content = each.value.content
  name    = each.key == "" ? cloudflare_zone.xvx_cz.name : "${each.key}.${cloudflare_zone.xvx_cz.name}"
  proxied = each.value.proxied
  ttl     = 1
  type    = "A"
}

# CNAME Records for xvx.cz
resource "cloudflare_dns_record" "xvx_cz_cname_records" {
  for_each = local.xvx_cz_cname_records

  zone_id = cloudflare_zone.xvx_cz.id
  comment = each.value.comment
  content = each.value.content
  name    = each.key == "" ? cloudflare_zone.xvx_cz.name : "${each.key}.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

# Creates a proxied CNAME for each Zero Trust tunnel ingress hostname.
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

# MX Records for xvx.cz
resource "cloudflare_dns_record" "xvx_cz_mx_records" {
  for_each = local.xvx_cz_mx_records

  zone_id  = cloudflare_zone.xvx_cz.id
  content  = each.value.content
  name     = cloudflare_zone.xvx_cz.name
  priority = each.value.priority
  proxied  = false
  ttl      = 1
  type     = "MX"
}

# TXT Records for xvx.cz
resource "cloudflare_dns_record" "xvx_cz_txt_records" {
  for_each = local.xvx_cz_txt_records

  zone_id = cloudflare_zone.xvx_cz.id
  content = each.value.content
  name    = each.value.name == "" ? cloudflare_zone.xvx_cz.name : "${each.value.name}.${cloudflare_zone.xvx_cz.name}"
  proxied = false
  ttl     = each.value.ttl
  type    = "TXT"
}

# Redirect stats.xvx.cz to UptimeRobot status page
resource "cloudflare_ruleset" "stats_xvx_cz" {
  zone_id     = cloudflare_zone.xvx_cz.id
  name        = "Redirect stats.xvx.cz to UptimeRobot status page"
  description = "Redirect stats.xvx.cz to UptimeRobot status page"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [{
    action = "redirect"
    action_parameters = {
      from_value = {
        status_code = 302
        target_url = {
          value = "https://stats.uptimerobot.com/${uptimerobot_psp.all_services.url_key}"
        }
      }
    }
    expression  = "(http.host eq \"stats.xvx.cz\")"
    description = "Redirect stats.xvx.cz to UptimeRobot status page"
    enabled     = true
  }]
}

# Compression Rules - Enable Zstandard (Zstd) Compression
resource "cloudflare_ruleset" "xvx_cz_compression" {
  zone_id     = cloudflare_zone.xvx_cz.id
  name        = "Compression Rules"
  description = "Enable Zstandard compression with Brotli and Gzip fallbacks"
  kind        = "zone"
  phase       = "http_response_compression"
  rules = [{
    action      = "compress_response"
    expression  = "true"
    description = "Enable Zstd compression"
    enabled     = true
    action_parameters = {
      algorithms = [
        { name = "zstd" },
        { name = "brotli" },
        { name = "gzip" },
      ]
    }
  }]
}

# Cache Rules - Cache default file extensions
resource "cloudflare_ruleset" "xvx_cz_cache" {
  zone_id     = cloudflare_zone.xvx_cz.id
  name        = "Cache Rules"
  description = "Cache default file extensions"
  kind        = "zone"
  phase       = "http_request_cache_settings"
  rules = [{
    action      = "set_cache_settings"
    expression  = "(http.request.uri.path.extension in {\"7z\" \"avi\" \"avif\" \"apk\" \"bin\" \"bmp\" \"bz2\" \"class\" \"css\" \"csv\" \"doc\" \"docx\" \"dmg\" \"ejs\" \"eot\" \"eps\" \"exe\" \"flac\" \"gif\" \"gz\" \"ico\" \"iso\" \"jar\" \"jpg\" \"jpeg\" \"js\" \"mid\" \"midi\" \"mkv\" \"mp3\" \"mp4\" \"ogg\" \"otf\" \"pdf\" \"pict\" \"pls\" \"png\" \"ppt\" \"pptx\" \"ps\" \"rar\" \"svg\" \"svgz\" \"swf\" \"tar\" \"tif\" \"tiff\" \"ttf\" \"webm\" \"webp\" \"woff\" \"woff2\" \"xls\" \"xlsx\" \"zip\" \"zst\"})"
    description = "Cache default file extensions"
    enabled     = true
    action_parameters = {
      cache = true
    }
  }]
}
