locals {
  # keep-sorted start block=yes newline_separated=yes
  # CNAME Records for mylabs.dev
  mylabs_dev_cname_records = {
    # keep-sorted start block=yes
    "" = {
      content                    = "petr.ruzicka.dev"
      comment                    = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied                    = true
      observatory_scheduled_test = true
    }
    "mt-link" = {
      content = "t.mailtrap.live"
      comment = "mailtrap domain tracking"
      proxied = false
    }
    "mt84" = {
      content = "smtp.mailtrap.live"
      comment = "mailtrap domain verification"
      proxied = false
    }
    "rwmt1._domainkey" = {
      content = "rwmt1.dkim.smtp.mailtrap.live"
      comment = "mailtrap DKIM"
      proxied = false
    }
    "rwmt2._domainkey" = {
      content = "rwmt2.dkim.smtp.mailtrap.live"
      comment = "mailtrap DKIM"
      proxied = false
    }
    "www" = {
      content = "petr.ruzicka.dev"
      comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied = true
    }
    # keep-sorted end
  }

  # MX Records for mylabs.dev - Mailtrap
  mylabs_dev_mx_records = {
    "mx1" = {
      content  = "smtp.mailtrap.live"
      priority = 10
      comment  = "Mailtrap MX record"
    }
  }

  # NS Records for AWS Route 53 delegation - mylabs.dev
  mylabs_dev_ns_records = {
    # keep-sorted start block=yes
    "aws-ns1" = {
      content = "ns-227.awsdns-28.com"
      name    = "aws"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "aws-ns2" = {
      content = "ns-1722.awsdns-23.co.uk"
      name    = "aws"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "aws-ns3" = {
      content = "ns-528.awsdns-02.net"
      name    = "aws"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "aws-ns4" = {
      content = "ns-1522.awsdns-62.org"
      name    = "aws"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "k8s-ns1" = {
      content = "ns-302.awsdns-37.com"
      name    = "k8s"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "k8s-ns2" = {
      content = "ns-971.awsdns-57.net"
      name    = "k8s"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "k8s-ns3" = {
      content = "ns-1154.awsdns-16.org"
      name    = "k8s"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    "k8s-ns4" = {
      content = "ns-1874.awsdns-42.co.uk"
      name    = "k8s"
      comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
    }
    # keep-sorted end
  }

  # TXT Records for mylabs.dev
  mylabs_dev_txt_records = {
    "_dmarc" = {
      content = "v=DMARC1; p=none; rua=mailto:dmarc@smtp.mailtrap.live; ruf=mailto:dmarc@smtp.mailtrap.live; rf=afrf; pct=100"
      comment = "mailtrap DMARC"
      name    = "_dmarc"
    }
    "spf" = {
      content = "v=spf1 include:_spf.smtp.mailtrap.live ~all"
      comment = "Mailtrap SPF"
      name    = ""
    }
  }
  # keep-sorted end
}

import {
  to = cloudflare_zone.mylabs_dev
  id = "2859c4d6f599a36a424765646b79904e"
}

# Zone for mylabs.dev
resource "cloudflare_zone" "mylabs_dev" {
  account = {
    id = local.cloudflare_account_id
  }
  name = "mylabs.dev"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_zone_dnssec" "mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  status  = "active"
}

resource "cloudflare_zone_setting" "mylabs_dev_min_tls_version" {
  zone_id    = cloudflare_zone.mylabs_dev.id
  setting_id = "min_tls_version"
  value      = "1.3"
}

resource "cloudflare_observatory_scheduled_test" "mylabs_dev" {
  for_each = { for k, v in local.mylabs_dev_cname_records : k => v if try(v.observatory_scheduled_test, false) }
  zone_id  = cloudflare_zone.mylabs_dev.id
  url      = each.key == "" ? "mylabs.dev" : "${each.key}.mylabs.dev"
}

# CNAME Records for mylabs.dev
resource "cloudflare_dns_record" "mylabs_dev_cname_records" {
  for_each = local.mylabs_dev_cname_records

  zone_id = cloudflare_zone.mylabs_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = each.key == "" ? cloudflare_zone.mylabs_dev.name : "${each.key}.${cloudflare_zone.mylabs_dev.name}"
  proxied = each.value.proxied
  ttl     = 1
  type    = "CNAME"
}

# NS Records for AWS Route 53 delegation - mylabs.dev
resource "cloudflare_dns_record" "mylabs_dev_ns_records" {
  for_each = local.mylabs_dev_ns_records

  zone_id = cloudflare_zone.mylabs_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = "${each.value.name}.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

# MX Records for mylabs.dev - Mailtrap
resource "cloudflare_dns_record" "mylabs_dev_mx_records" {
  for_each = local.mylabs_dev_mx_records

  zone_id  = cloudflare_zone.mylabs_dev.id
  comment  = each.value.comment
  content  = each.value.content
  name     = cloudflare_zone.mylabs_dev.name
  priority = each.value.priority
  proxied  = false
  ttl      = 1
  type     = "MX"
}

# TXT Records for mylabs.dev
resource "cloudflare_dns_record" "mylabs_dev_txt_records" {
  for_each = local.mylabs_dev_txt_records

  zone_id = cloudflare_zone.mylabs_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = each.value.name == "" ? cloudflare_zone.mylabs_dev.name : "${each.value.name}.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

# Redirect mylabs.dev and www.mylabs.dev to petr.ruzicka.dev
resource "cloudflare_ruleset" "mylabs_dev_redirects" {
  zone_id = cloudflare_zone.mylabs_dev.id
  name    = "Redirect mylabs.dev to petr.ruzicka.dev"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [
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
      expression  = "(http.host eq \"www.mylabs.dev\") or (http.host eq \"mylabs.dev\")"
      description = "Redirect mylabs.dev and www.mylabs.dev to petr.ruzicka.dev"
      enabled     = true
    }
  ]
}

# Compression Rules - Enable Zstandard (Zstd) Compression
resource "cloudflare_ruleset" "mylabs_dev_compression" {
  zone_id     = cloudflare_zone.mylabs_dev.id
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
resource "cloudflare_ruleset" "mylabs_dev_cache" {
  zone_id     = cloudflare_zone.mylabs_dev.id
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
