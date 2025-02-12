import {
  to = cloudflare_zone.mylabs_dev
  id = "2859c4d6f599a36a424765646b79904e"
}

resource "cloudflare_zone" "mylabs_dev" {
  account = {
    id = var.cloudflare_account_id
  }
  name = "mylabs.dev"
  type = "full"
}

# keep-sorted start block=yes newline_separated=yes
resource "cloudflare_dns_record" "cname_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = "@"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = "www"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "mx1_mylabs_dev" {
  zone_id  = cloudflare_zone.mylabs_dev.id
  comment  = "Used by CloudFlare Email Routing"
  content  = "route3.mx.cloudflare.net"
  name     = "@"
  priority = 48
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx2_mylabs_dev" {
  zone_id  = cloudflare_zone.mylabs_dev.id
  comment  = "Used by CloudFlare Email Routing"
  content  = "route2.mx.cloudflare.net"
  name     = "@"
  priority = 43
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "mx3_mylabs_dev" {
  zone_id  = cloudflare_zone.mylabs_dev.id
  content  = "route1.mx.cloudflare.net"
  name     = "@"
  priority = 6
  proxied  = false
  ttl      = 1
  type     = "MX"
}

resource "cloudflare_dns_record" "ns1_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-302.awsdns-37.com"
  name    = "k8s"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns2_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-971.awsdns-57.net"
  name    = "k8s"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns3_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1154.awsdns-16.org"
  name    = "k8s"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns4_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1874.awsdns-42.co.uk"
  name    = "k8s"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns5_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-78.awsdns-09.com"
  name    = "k8s"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "spf_txt_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
  name    = "@"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "txt_cf2024_1_domainkey_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
  name    = "cf2024-1._domainkey"
  proxied = false
  ttl     = 1
  type    = "TXT"
}
# keep-sorted end
