locals {
  # keep-sorted start block=yes newline_separated=yes
  # CNAME Records for ruzicka.dev
  ruzicka_dev_cname_records = {
    # keep-sorted start block=yes
    "" = {
      content = "petr.ruzicka.dev"
      comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied = true
    }
    "blog" = {
      content = "ruzickap.github.io"
      comment = "ruzickap.github.io - personal blog 🏠 (https://github.com/ruzickap/ruzickap.github.io)"
      proxied = true
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
      comment  = ""
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
      comment = ""
    }
    "spf" = {
      content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
      name    = ""
      comment = ""
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
    id = var.cloudflare_account_id
  }
  name = "ruzicka.dev"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
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
