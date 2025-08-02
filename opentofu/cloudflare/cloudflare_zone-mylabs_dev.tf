locals {
  # keep-sorted start block=yes newline_separated=yes
  # CNAME Records for mylabs.dev
  mylabs_dev_cname_records = {
    # keep-sorted start block=yes
    "" = {
      content = "petr.ruzicka.dev"
      comment = "Personal page (https://github.com/ruzickap/petr.ruzicka.dev)"
      proxied = true
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
    id = var.cloudflare_account_id
  }
  name = "mylabs.dev"
  type = "full"

  lifecycle {
    prevent_destroy = true
  }
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

# TXT Records for mylabs.dev
resource "cloudflare_dns_record" "mylabs_dev_txt_records" {
  for_each = local.mylabs_dev_txt_records

  zone_id = cloudflare_zone.mylabs_dev.id
  comment = each.value.comment
  content = each.value.content
  name    = "${each.key}.${cloudflare_zone.mylabs_dev.name}"
  proxied = false
  ttl     = 1
  type    = "TXT"
}

# Disabled - Example page rule for reference
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
