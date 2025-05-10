import {
  to = cloudflare_zone.ruzicka_dev
  id = "452e45a673326608122e759793a713f3"
}

resource "cloudflare_zone" "ruzicka_dev" {
  account = {
    id = var.cloudflare_account_id
  }
  name = "ruzicka.dev"
  type = "full"
}

# keep-sorted start block=yes newline_separated=yes
resource "cloudflare_dns_record" "cname_blog_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "ruzickap.github.io - personal blog 🏠 (https://github.com/ruzickap/ruzickap.github.io)"
  content = "ruzickap.github.io"
  name    = "blog.ruzicka.dev"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_petr_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "ruzickap.github.io"
  name    = "petr.ruzicka.dev"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = "ruzicka.dev"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_stats_ruzickap_github_io_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "GoatCounter for Petr's Blog (https://www.goatcounter.com/help/faq#custom-domain)"
  content = "ruzickap-github-io.goatcounter.com"
  name    = "stats-ruzickap-github-io.ruzicka.dev"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = "www.ruzicka.dev"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "mx1_ruzicka_dev" {
  zone_id  = cloudflare_zone.ruzicka_dev.id
  content  = "route1.mx.cloudflare.net"
  name     = "ruzicka.dev"
  priority = 72
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx2_ruzicka_dev" {
  zone_id  = cloudflare_zone.ruzicka_dev.id
  comment  = "Used by CloudFlare Email Routing"
  content  = "route2.mx.cloudflare.net"
  name     = "ruzicka.dev"
  priority = 11
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx3_ruzicka_dev" {
  zone_id  = cloudflare_zone.ruzicka_dev.id
  comment  = "Used by CloudFlare Email Routing"
  content  = "route3.mx.cloudflare.net"
  name     = "ruzicka.dev"
  priority = 20
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "spf_txt_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
  name    = "ruzicka.dev"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_cf2024_1_domainkey_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  name    = "cf2024-1._domainkey.ruzicka.dev"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_github_pages_challenge_ruzickap_ruzicka_dev" {
  zone_id = cloudflare_zone.ruzicka_dev.id
  comment = "GitHub Pages custom domain verification for ruzicka.dev domain (https://github.com/settings/pages)"
  content = "\"d2344c41a13a4a413464c8d118fa60\""
  name    = "_github-pages-challenge-ruzickap.ruzicka.dev"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

# keep-sorted end
