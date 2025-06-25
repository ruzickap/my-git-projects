# Needs: Account - Cloudflare Pages, Project - Cloudflare Pages
resource "cloudflare_pages_project" "ruzickap_github_io" {
  account_id        = var.cloudflare_account_id
  name              = "ruzickap-github-io"
  production_branch = "main"
}
