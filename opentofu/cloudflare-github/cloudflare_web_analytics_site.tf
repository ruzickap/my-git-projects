resource "cloudflare_web_analytics_site" "ruzickap_github_io" {
  account_id   = local.cloudflare_account_id
  auto_install = false
  host         = "ruzickap.github.io"
}
