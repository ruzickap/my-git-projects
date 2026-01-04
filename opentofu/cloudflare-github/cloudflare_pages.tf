locals {
  cloudflare_pages_projects = {
    # keep-sorted start
    petr_ruzicka_dev   = "petr-ruzicka-dev"
    ruzickap_github_io = "ruzickap-github-io"
    xvx_cz             = "xvx-cz"
    # keep-sorted end
  }
}

resource "cloudflare_pages_project" "projects" {
  for_each          = local.cloudflare_pages_projects
  account_id        = local.cloudflare_account_id
  name              = each.value
  production_branch = "main"
}
