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

  lifecycle {
    prevent_destroy = true
  }
}

###############################################
# CNAME
###############################################
resource "cloudflare_dns_record" "cname_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = cloudflare_zone.mylabs_dev.name
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_www_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
  content = "petr.ruzicka.dev"
  name    = "www.${cloudflare_zone.mylabs_dev.name}"
  proxied = true
  ttl     = 1
  type    = "CNAME"
}

###############################################
# aws.mylabs.dev
###############################################
resource "cloudflare_dns_record" "ns1_aws_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-227.awsdns-28.com"
  name    = "aws.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

###############################################
# k8s.mylabs.dev
###############################################
resource "cloudflare_dns_record" "ns1_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-302.awsdns-37.com"
  name    = "k8s.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns2_aws_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1722.awsdns-23.co.uk"
  name    = "aws.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns2_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-971.awsdns-57.net"
  name    = "k8s.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns3_aws_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-528.awsdns-02.net"
  name    = "aws.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns3_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1154.awsdns-16.org"
  name    = "k8s.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns4_aws_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1522.awsdns-62.org"
  name    = "aws.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

resource "cloudflare_dns_record" "ns4_k8s_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "AWS Route 53 domain delegation to ruzicka-sbx01"
  content = "ns-1874.awsdns-42.co.uk"
  name    = "k8s.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "NS"
}

###############################################
# Mailtrap
###############################################
resource "cloudflare_dns_record" "cname_mt84_link_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Mailtrap domain verification"
  content = "smtp.mailtrap.live"
  name    = "mt84.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_rwmt1_domainkey_link_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Mailtrap DKIM"
  content = "rwmt1.dkim.smtp.mailtrap.live"
  name    = "rwmt1._domainkey.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "cname_rwmt2_domainkey_link_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Mailtrap DKIM"
  content = "rwmt2.dkim.smtp.mailtrap.live"
  name    = "rwmt2._domainkey.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

resource "cloudflare_dns_record" "txt_dmarc_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Mailtrap DMARC"
  content = "v=DMARC1; p=none; rua=mailto:dmarc@smtp.mailtrap.live; ruf=mailto:dmarc@smtp.mailtrap.live; rf=afrf; pct=100"
  name    = "_dmarc.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

resource "cloudflare_dns_record" "cname_mt_link_mylabs_dev" {
  zone_id = cloudflare_zone.mylabs_dev.id
  comment = "Mailtrap domain tracking"
  content = "t.mailtrap.live"
  name    = "mt-link.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "CNAME"
}

###############################################
# Page Rules
###############################################
# resource "cloudflare_page_rule" "example_page_rule" {
#   zone_id  = cloudflare_zone.mylabs_dev.id
#   target   = "mylabs2.dev/*"
#   priority = 1
#   status   = "active"
#   actions = {
#     forwarding_url = {
#       url         = "https://petr.ruzicka.dev/"
#       status_code = 302
#     }
#   }
# }
