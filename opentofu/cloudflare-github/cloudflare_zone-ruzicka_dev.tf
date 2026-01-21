locals {
  # keep-sorted start block=yes newline_separated=yes
  # CNAME Records for ruzicka.dev
  ruzicka_dev_cname_records = {
    # keep-sorted start block=yes
    "" = {
      content                    = "petr.ruzicka.dev"
      comment                    = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied                    = true
      observatory_scheduled_test = true
    }
    "blog" = {
      content                    = "ruzickap.github.io"
      comment                    = "Blog (https://github.com/ruzickap/ruzickap.github.io)"
      proxied                    = true
      observatory_scheduled_test = true
    }
    "petr" = {
      content = "ruzickap.github.io"
      comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied = false
    }
    "stats-ruzickap-github-io" = {
      content = "ruzickap-github-io.goatcounter.com"
      comment = "GoatCounter for Petr's Blog (https://www.goatcounter.com/help/faq#custom-domain)"
      proxied = false
    }
    "www" = {
      content = "petr.ruzicka.dev"
      comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied = true
    }
    # keep-sorted end
  }

  # MX Records for ruzicka.dev - CloudFlare Email Routing
  ruzicka_dev_mx_records = {
    # keep-sorted start block=yes
    "mx1" = {
      content  = "route1.mx.cloudflare.net"
      priority = 72
      comment  = "Used by CloudFlare Email Routing"
    }
    "mx2" = {
      content  = "route2.mx.cloudflare.net"
      priority = 11
      comment  = "Used by CloudFlare Email Routing"
    }
    "mx3" = {
      content  = "route3.mx.cloudflare.net"
      priority = 20
      comment  = "Used by CloudFlare Email Routing"
    }
    # keep-sorted end
  }

  # TXT Records for ruzicka.dev
  ruzicka_dev_txt_records = {
    # keep-sorted start block=yes
    "_github-pages-challenge-ruzickap" = {
      content = "\"d2344c41a13a4a413464c8d118fa60\""
      name    = "_github-pages-challenge-ruzickap"
      comment = "GitHub Pages custom domain verification for ruzicka.dev domain (https://github.com/settings/pages)"
    }
    "cf2024-1._domainkey" = {
      content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
      name    = "cf2024-1._domainkey"
      comment = "Cloudflare DKIM"
    }
    "google-site-verification" = {
      content = "\"google-site-verification=y45N8avw0zpYwbPL8ncwcQC79xOBMNZcvD0380LRsBU\""
      name    = ""
      comment = "Google Search Console site verification"
    }
    "spf" = {
      content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
      name    = ""
      comment = "Cloudflare SPF"
    }
    # keep-sorted end
  }
  # keep-sorted end
}

import {
  to = cloudflare_zone.ruzicka_dev
  id = "452e45a673326608122e759793a713f3"
}

# Zone for ruzicka.dev
resource "cloudflare_zone" "ruzicka_dev" {
  account = {
    id = local.cloudflare_account_id
  }
  name = "ruzicka.dev"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_dnssec" "ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  status  = "active"
}

resource "cloudflare_zone_setting" "ruzicka_dev_min_tls_version" {
  zone_id    = cloudflare_zone.ruzicka_dev.id
  setting_id = "min_tls_version"
  value      = "1.3"
}

resource "cloudflare_observatory_scheduled_test" "ruzicka_dev" {
  for_each = { for k, v in local.ruzicka_dev_cname_records : k => v if try(v.observatory_scheduled_test, false) }
  zone_id  = cloudflare_zone.ruzicka_dev.id
  url      = each.key == "" ? "ruzicka.dev" : "${each.key}.ruzicka.dev"
}

# CNAME Records for ruzicka.dev
resource "cloudflare_dns_record" "ruzicka_dev_cname_records" {
  for_each = local.ruzicka_dev_cname_records

  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = each.key == "" ? cloudflare_zone.ruzicka_dev.name : "${each.key}.${cloudflare_zone.ruzicka_dev.name}"
  proxied = each.value.proxied
  ttl     = 1
  type    = "CNAME"
}

# MX Records for ruzicka.dev - CloudFlare Email Routing
resource "cloudflare_dns_record" "ruzicka_dev_mx_records" {
  for_each = local.ruzicka_dev_mx_records

  zone_id  = cloudflare_zone.ruzicka_dev.id
  comment  = each.value.comment
  content  = each.value.content
  name     = cloudflare_zone.ruzicka_dev.name
  priority = each.value.priority
  proxied  = false
  ttl      = 1
  type     = "MX"
}

# TXT Records for ruzicka.dev
resource "cloudflare_dns_record" "ruzicka_dev_txt_records" {
  for_each = local.ruzicka_dev_txt_records

  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = each.value.name == "" ? cloudflare_zone.ruzicka_dev.name : "${each.value.name}.${cloudflare_zone.ruzicka_dev.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

# Redirect rules for ruzicka.dev
resource "cloudflare_ruleset" "ruzicka_dev_redirects" {
  zone_id     = cloudflare_zone.ruzicka_dev.id
  name        = "Redirect rules for ruzicka.dev"
  description = "HTTP redirect rules for ruzicka.dev domain and subdomains"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 302
          target_url = {
            expression = "concat(\"https://ruzickap.github.io\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
      expression  = "(http.host eq \"blog.ruzicka.dev\")"
      description = "Redirect blog.ruzicka.dev to ruzickap.github.io"
      enabled     = true
    },
    {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code = 302
          target_url = {
            value = "https://petr.ruzicka.dev/"
          }
          preserve_query_string = false
        }
      }
      expression  = "(http.host eq \"ruzicka.dev\") or (http.host eq \"www.ruzicka.dev\")"
      description = "Redirect ruzicka.dev and www.ruzicka.dev to petr.ruzicka.dev"
      enabled     = true
    }
  ]
}

# Compression Rules - Enable Zstandard (Zstd) Compression
resource "cloudflare_ruleset" "ruzicka_dev_compression" {
  zone_id     = cloudflare_zone.ruzicka_dev.id
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
resource "cloudflare_ruleset" "ruzicka_dev_cache" {
  zone_id     = cloudflare_zone.ruzicka_dev.id
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
