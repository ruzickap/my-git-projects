resource "cloudflare_web_analytics_site" "ruzickap_github_io" {
  account_id   = local.cloudflare_account_id
  auto_install = false
  host         = "ruzickap.github.io"
}

output "cloudflare_web_analytics_site_ruzickap_github_io_token" {
  description = "Web Analytics site token for ruzickap.github.io"
  value       = cloudflare_web_analytics_site.ruzickap_github_io.site_token
}
