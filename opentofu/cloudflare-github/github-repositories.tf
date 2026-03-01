locals {
  # keep-sorted start block=yes
  all_github_repositories = merge(local.github_repositories_existing, local.github_repositories)
  # Default secrets applied to all GitHub repositories
  github_action_default_secrets = {
    "MY_RENOVATE_GITHUB_APP_ID" = data.sops_file.env_yaml.data["MY_RENOVATE_GITHUB_APP_ID"]
    # kics-scan ignore-line - False positive: value comes from encrypted SOPS file, not hardcoded
    "MY_RENOVATE_GITHUB_PRIVATE_KEY" = data.sops_file.env_yaml.data["MY_RENOVATE_GITHUB_PRIVATE_KEY"]
    "MY_SLACK_BOT_TOKEN"             = data.sops_file.env_yaml.data["MY_SLACK_BOT_TOKEN"]
    "MY_SLACK_CHANNEL_ID"            = data.sops_file.env_yaml.data["MY_SLACK_CHANNEL_ID"]
  }
  github_repositories = {
    "caisp_notes" = {
      name        = "caisp-notes"
      description = "Certified AI Security Professional Notes"
      visibility  = "private"
      topics      = ["ai", "ai-security", "caisp", "caisp-exam", "caisp-exam-preparation", "devsecops", "notes", "security"]
    }
    "container_image_scans" = {
      name        = "container-image-scans"
      description = "Container image scans"
      topics      = ["container", "container-image", "container-security", "cve", "image", "public", "security", "vulnerability"]
      pages = [{
        source = [{
          branch = "gh-pages"
        }]
      }]
      # secrets = {
      #   "SOPS_AGE_KEY" = data.sops_file.env_yaml.data["SOPS_AGE_KEY_CONTAINER_IMAGE_SCANS"]
      # }
    }
    "k8s_multicluster_gitops" = {
      name        = "k8s-multicluster-gitops"
      description = "Infrastructure as Code for provisioning multiple Kubernetes clusters, managed using GitOps with ArgoCD"
      topics      = ["aks", "argocd", "eks", "gitops", "infrastructure-as-code", "k8s", "k8s-gitops", "kind", "kubernetes", "multi-cluster", "terraform", "vcluster"] # codespell:ignore
    }
    "pre_commit_wizcli" = {
      name        = "pre-commit-wizcli"
      description = "pre-commit hook for WizCLI that checks your code"
      topics      = ["pre-commit", "wizcli", "wiz"]
      pages = [{
        source = [{
          branch = "gh-pages"
        }]
      }]
      secrets = {
        "WIZ_CLIENT_ID"     = data.sops_file.env_yaml.data["WIZ_CLIENT_ID"]
        "WIZ_CLIENT_SECRET" = data.sops_file.env_yaml.data["WIZ_CLIENT_SECRET"]
      }
    }
    "wiz_certification_notes" = {
      name        = "wiz-certification-notes"
      description = "Wiz Certified exams Notes"
      visibility  = "private"
      topics      = ["certification", "notes", "security", "wiz", "wiz-exam", "wiz-exam-preparation"]
    }
  }
  #trivy:ignore:avd-git-0001 Repository is public
  github_repositories_existing = {
    # keep-sorted start block=yes
    "action_my_broken_link_checker" = {
      name        = "action-my-broken-link-checker"
      description = "A GitHub Action for checking broken links"
      topics      = ["actions", "broken-links", "checker", "github-action", "github-actions", "link-checker", "link-checking", "links", "public", "url-checker", "url-checking", "website"]
    }
    "action_my_markdown_link_checker" = {
      name        = "action-my-markdown-link-checker"
      description = "A GitHub Action for checking broken links in Markdown files"
      topics      = ["actions", "broken-links", "checker", "github-action", "github-actions", "link-checker", "link-checking", "links", "markdown", "public", "url-checker", "url-checking", "website"]
    }
    "action_my_markdown_linter" = {
      name        = "action-my-markdown-linter"
      description = "Style checking and linting for Markdown files"
      topics      = ["github-action", "github-actions", "lint", "linter", "linting", "linters", "markdown", "public"]
    }
    "ansible_my_workstation" = {
      name        = "ansible-my_workstation"
      description = "Ansible playbooks to configure my workstation based on Fedora / macOS"
      topics      = ["ansible", "ansible-playbook", "configuration", "fedora", "macos", "public", "workstation"]
    }
    "ansible_openwrt" = {
      name        = "ansible-openwrt"
      description = "Ansible playbooks configuring Openwrt devices (Wi-Fi routers)"
      topics      = ["ansible", "ansible-playbook", "openwrt", "public", "router", "wifi"]
    }
    "ansible_raspberry_pi_os" = {
      name        = "ansible-raspberry-pi-os"
      description = "Configure Raspberry Pi OS (RPi) using Ansible"
      topics      = ["ansible", "grafana", "kodi", "node-exporter", "public", "prometheus", "raspberry-pi", "raspberry-pi-os", "rpi"]
      secrets = {
        # kics-scan ignore-line - False positive: value comes from encrypted SOPS file, not hardcoded
        "WIFI_PASSWORD" = data.sops_file.env_yaml.data["WIFI_PASSWORD"]
        "WIFI_SSID"     = data.sops_file.env_yaml.data["WIFI_SSID"]
      }
    }
    "brewwatch" = {
      name        = "brewwatch"
      description = "A modern web app to discover and track newly added Homebrew packages and casks"
      visibility  = "private"
      topics      = ["brew", "casks", "formulae", "homebrew", "lovable", "packages", "tracker", "watch"]
    }
    "cheatsheet_atom" = {
      name        = "cheatsheet-atom"
      description = "Atom Keyboard Shortcuts Cheatsheet"
      topics      = ["atom", "cheatsheet", "cheatsheet-atom", "latex", "public"]
    }
    "cheatsheet_macos" = {
      name        = "cheatsheet-macos"
      description = "MacOS Keyboard Shortcuts"
      topics      = ["cheatsheet", "cheatsheet-mscos", "latex", "macos", "public"]
    }
    "cheatsheet_systemd" = {
      name        = "cheatsheet-systemd"
      description = "Cheatsheet for systemd"
      topics      = ["cheatsheet", "cheatsheet-systemd", "latex", "public", "systemd"]
    }
    "cks_notes" = {
      name        = "cks-notes"
      description = "CKS Notes"
      topics      = ["cks", "cks-exam", "cks-exam-preparation", "k8s", "k8s-security", "kubernetes", "notes", "public", "security"]
    }
    "cv" = {
      name        = "cv"
      description = "My CV in LaTeX"
      visibility  = "private"
      topics      = ["cv", "latex", "private", "resume", "texlive"]
    }
    "gha_test" = {
      name         = "gha-test"
      description  = "GitHub Action Test repository"
      homepage_url = "https://petr.ruzicka.dev"
      topics       = ["actions", "ci", "github", "test", "github-action", "gha"]
    }
    "malware_cryptominer_container" = {
      name         = "malware-cryptominer-container"
      description  = "Container image with malware and crypto miner for testing purposes"
      homepage_url = "https://artifacthub.io/packages/container/malware-cryptominer-container/malware-cryptominer-container"
      topics       = ["container", "crypto", "cryptominer", "dockerfile", "eicar", "image", "malware", "public", "test", "xmrig"]
      secrets = {
        # keep-sorted start
        # kics-scan ignore-line - False positive: value comes from encrypted SOPS file, not hardcoded
        "DOCKERHUB_CONTAINER_REGISTRY_PASSWORD" = data.sops_file.env_yaml.data["DOCKERHUB_CONTAINER_REGISTRY_PASSWORD"]
        "DOCKERHUB_CONTAINER_REGISTRY_USER"     = data.sops_file.env_yaml.data["DOCKERHUB_CONTAINER_REGISTRY_USER"]
        # kics-scan ignore-line - False positive: value comes from encrypted SOPS file, not hardcoded
        "QUAY_CONTAINER_REGISTRY_PASSWORD" = data.sops_file.env_yaml.data["QUAY_CONTAINER_REGISTRY_PASSWORD"]
        "QUAY_CONTAINER_REGISTRY_USER"     = data.sops_file.env_yaml.data["QUAY_CONTAINER_REGISTRY_USER"]
        # keep-sorted end
      }
    }
    "my_git_projects" = {
      name        = "my-git-projects"
      description = "My GitHub Projects"
      topics      = ["github", "projects", "templates"]
      secrets = {
        # keep-sorted start
        "CLOUDFLARE_R2_ACCESS_KEY_ID"                = cloudflare_account_token.opentofu_cloudflare_github.id
        "CLOUDFLARE_R2_ENDPOINT_URL_S3"              = "https://${local.cloudflare_account_id}.r2.cloudflarestorage.com"
        "CLOUDFLARE_R2_SECRET_ACCESS_KEY"            = sha256(data.sops_file.env_yaml.data["OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN"])
        "OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN"       = data.sops_file.env_yaml.data["OPENTOFU_CLOUDFLARE_GITHUB_API_TOKEN"]
        "RUZICKA_SBX01_AWS_ROLE_TO_ASSUME"           = data.sops_file.env_yaml.data["RUZICKA_SBX01_AWS_ROLE_TO_ASSUME"]
        "SOPS_AGE_KEY"                               = data.sops_file.env_yaml.data["SOPS_AGE_KEY"]
        "TF_VAR_GH_TOKEN_OPENTOFU_CLOUDFLARE_GITHUB" = data.sops_file.env_yaml.data["TF_VAR_gh_token_opentofu_cloudflare_github"]
        "TF_VAR_OPENTOFU_ENCRYPTION_PASSPHRASE"      = data.sops_file.env_yaml.data["TF_VAR_opentofu_encryption_passphrase"]
        # keep-sorted end
      }
    }
    "old_stuff" = {
      name        = "old_stuff"
      description = "Obsolete and old things"
      topics      = ["bash", "perl", "old", "scripts"]
    }
    "petr_ruzicka_dev" = {
      name         = "petr.ruzicka.dev"
      description  = "Personal page"
      homepage_url = "https://petr.ruzicka.dev/"
      pages = [{
        cname    = "petr.ruzicka.dev"
        html_url = "https://petr.ruzicka.dev/"
        source = [{
          branch = "gh-pages"
        }]
      }]
      topics = ["personal", "personal-website", "public", "web", "website"]
      secrets = {
        "CLOUDFLARE_ACCOUNT_ID" = local.cloudflare_account_id
        "CLOUDFLARE_API_TOKEN"  = cloudflare_account_token.pages_petr_ruzicka_dev.value
      }
    }
    "ruzickap" = {
      name        = "ruzickap"
      description = "GitHub profile repository"
      topics      = ["github", "profile"]
    }
    "ruzickap_github_io" = {
      name            = "ruzickap.github.io"
      description     = "ruzickap.github.io - personal blog 🏠"
      has_discussions = true
      homepage_url    = "https://ruzickap.github.io/"
      pages = [{
        html_url = "https://ruzickap.github.io"
        source = [{
          branch = "gh-pages"
        }]
      }]
      topics = ["blog", "github", "github-actions", "jekyll", "markdown", "personal-website", "public", "web", "website"]
      secrets = {
        # keep-sorted start
        "AWS_ROLE_TO_ASSUME"                  = data.sops_file.env_yaml.data["RUZICKA_SBX01_AWS_ROLE_TO_ASSUME"]
        "CLOUDFLARE_ACCOUNT_ID"               = local.cloudflare_account_id
        "CLOUDFLARE_API_TOKEN"                = cloudflare_account_token.pages_ruzickap_github_io.value
        "CLOUDFLARE_WEB_ANALYTICS_SITE_TOKEN" = cloudflare_web_analytics_site.ruzickap_github_io.site_token
        "GOOGLE_CLIENT_ID"                    = data.sops_file.env_yaml.data["GOOGLE_CLIENT_ID"]
        "GOOGLE_CLIENT_SECRET"                = data.sops_file.env_yaml.data["GOOGLE_CLIENT_SECRET"]
        "MY_ATLASSIAN_PERSONAL_TOKEN"         = data.sops_file.env_yaml.data["MY_ATLASSIAN_PERSONAL_TOKEN"]
        # keep-sorted end
      }
    }
    "ruzickovabozena_xvx_cz" = {
      name         = "ruzickovabozena.xvx.cz"
      description  = "ruzickovabozena.xvx.cz"
      homepage_url = "https://ruzickovabozena.xvx.cz"
      pages = [{
        cname    = "ruzickovabozena.xvx.cz"
        html_url = "https://ruzickovabozena.xvx.cz"
        source = [{
          branch = "gh-pages"
        }]
      }]
      topics = ["personal-site", "personal-website", "web", "website"]
    }
    "test_usb_stick_for_tv" = {
      name        = "test_usb_stick_for_tv"
      description = "This script stores testing videos/music/pictures on your USB stick, which can be used for testing TVs"
      topics      = ["android-tv", "test", "testing", "testing-tools", "testing-tvs", "tv", "usb"]
    }
    "xvx_cz" = {
      name         = "xvx.cz"
      description  = "xvx.cz"
      homepage_url = "https://xvx.cz/"
      pages = [{
        cname    = "xvx.cz"
        html_url = "https://xvx.cz"
        source = [{
          branch = "gh-pages"
        }]
      }]
      topics = ["personal", "personal-website", "public", "web", "website", "xvx", "xvx-cz"]
      secrets = {
        "CLOUDFLARE_ACCOUNT_ID" = local.cloudflare_account_id
        "CLOUDFLARE_API_TOKEN"  = cloudflare_account_token.pages_xvx_cz.value
      }
    }
    # keep-sorted end
  }
  # keep-sorted end
}

import {
  for_each = local.github_repositories_existing
  id       = each.value.name
  to       = github_repository.this[each.key]
}

resource "github_repository" "this" {
  #checkov:skip=CKV_GIT_1:Ensure GitHub repository is Private
  #checkov:skip=CKV2_GIT_1:Ensure each Repository has branch protection associated
  for_each = local.all_github_repositories
  # Merge settings
  allow_merge_commit     = false # disable merge commits, use squash/rebase only
  allow_update_branch    = true  # allow updating PR branches from base branch
  delete_branch_on_merge = true  # auto-delete head branches after merge

  # Repository initialization
  auto_init        = true         # create initial commit with README
  license_template = "apache-2.0" # default license for new repos

  # Repository metadata
  name         = each.value.name
  description  = try(each.value.description, "")
  homepage_url = try(each.value.homepage_url, "")
  visibility   = try(each.value.visibility, "public") #trivy:ignore:AVD-GIT-0001

  # Repository features
  has_discussions = try(each.value.has_discussions, false)
  has_issues      = true  # enable issue tracking
  has_projects    = false # disable GitHub Projects
  has_wiki        = false # disable wiki (prefer docs in repo)

  # Security
  vulnerability_alerts = true # enable Dependabot vulnerability alerts

  dynamic "pages" {
    for_each = try(each.value.pages, [])
    content {
      cname = try(pages.value.cname, null)
      dynamic "source" {
        for_each = try(pages.value.source, [])
        content {
          branch = source.value.branch
          path   = try(source.value.path, null)
        }
      }
    }
  }

  dynamic "security_and_analysis" {
    for_each = try(each.value.visibility, "") != "private" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_workflow_repository_permissions" "this" {
  for_each                         = local.all_github_repositories
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = true
  repository                       = github_repository.this[each.key].name
}

resource "github_actions_secret" "this" {
  # checkov:skip=CKV_GIT_4:GitHub encrypts secrets automatically when stored via plaintext_value
  for_each = {
    for item in flatten([
      for repo_key, repo in local.all_github_repositories : [
        for secret_name, secret_value in merge(local.github_action_default_secrets, try(repo.secrets, {})) : {
          key         = "${repo_key}-${secret_name}"
          repository  = repo.name
          secret_name = secret_name
          # kics-scan ignore-line
          secret_value = secret_value
        }
      ]
    ]) : item.key => item
  }
  repository      = each.value.repository
  secret_name     = each.value.secret_name
  plaintext_value = each.value.secret_value
}

# Import existing GitHub Repositories
import {
  for_each = local.github_repositories_existing
  id       = each.value.name
  to       = github_repository_topics.this[each.key]
}

resource "github_repository_topics" "this" {
  for_each   = local.all_github_repositories
  repository = each.value.name
  topics     = try(each.value.topics, [])
}

resource "github_repository_ruleset" "main" {
  for_each    = { for k, v in local.all_github_repositories : k => v if try(v.visibility != "private", true) }
  name        = "main"
  repository  = each.value.name
  target      = "branch"
  enforcement = "active"

  # My Renovate App
  # Renovate bot - needs direct access to create update branches
  bypass_actors {
    actor_id    = 199026 # Renovate GitHub App ID
    actor_type  = "Integration"
    bypass_mode = "always" # allow direct pushes without PR
  }

  # Repository admin - can bypass via PR only
  bypass_actors {
    actor_id    = 5 # admin role ID
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request" # must still use PR workflow
  }

  # Apply ruleset to default branch only
  conditions {
    ref_name {
      exclude = []
      include = ["~DEFAULT_BRANCH"]
    }
  }

  rules {
    # Branch protection rules
    deletion                = true # prevent branch deletion
    non_fast_forward        = true # prevent force pushes
    required_linear_history = true # require linear commit history (no merge commits)
    # required_signatures     = true

    # Pull request requirements
    pull_request {
      dismiss_stale_reviews_on_push     = true # invalidate approvals when new commits are pushed
      require_code_owner_review         = true # require approval from code owners
      require_last_push_approval        = true # last pusher cannot self-approve
      required_approving_review_count   = 2    # minimum number of approving reviews
      required_review_thread_resolution = true # all conversations must be resolved
    }

    # CI/CD status checks
    required_status_checks {
      strict_required_status_checks_policy = true # branch must be up-to-date before merging
      required_check {
        context = "semantic-pull-request" # enforce conventional commit PR titles
      }
    }
  }
}
