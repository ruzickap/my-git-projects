terraform {
  backend "s3" {
    bucket                      = "ruzickap-my-git-projects-opentofu-state-file"
    key                         = "ruzickap-my-git-projects-opentofu-github-repositories.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
  }
  encryption {
    key_provider "pbkdf2" "mykey" {
      passphrase = var.opentofu_encryption_passphrase
    }
    method "aes_gcm" "new_method" {
      keys = key_provider.pbkdf2.mykey
    }
    state {
      method   = method.aes_gcm.new_method
      enforced = true
    }
  }
  required_version = "~> 1.9"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {}

locals {
  all_github_repositories = merge(local.github_repositories_existing, local.github_repositories)
  default_github_actions_secrets = [
    {
      secret_name     = "MY_RENOVATE_GITHUB_APP_ID"
      plaintext_value = var.my_renovate_github_app_id
    },
    {
      secret_name     = "MY_RENOVATE_GITHUB_PRIVATE_KEY"
      plaintext_value = var.my_renovate_github_private_key
    },
    {
      secret_name     = "MY_SLACK_BOT_TOKEN"
      plaintext_value = var.my_slack_bot_token
    },
    {
      secret_name     = "MY_SLACK_CHANNEL_ID"
      plaintext_value = var.my_slack_channel_id
    },
  ]
  github_repositories = {
    "container-image-upgrade-test" = {
      name                   = "container-image-upgrade-test"
      description            = "Container Image Upgrade Test Scan"
      topics                 = ["container-image", "container", "scan", "security", "upgrade"]
      github_actions_secrets = local.default_github_actions_secrets
    },
    "k8s_multicluster_gitops" = {
      name                   = "k8s-multicluster-gitops"
      description            = "Infrastructure as Code for provisioning multiple Kubernetes clusters, managed using GitOps with ArgoCD"
      topics                 = ["aks", "argocd", "eks", "gitops", "infrastructure-as-code", "k8s", "k8s-gitops", "kind", "kubernetes", "multi-cluster", "terraform", "vcluster"]
      github_actions_secrets = local.default_github_actions_secrets
    },
  }
  #trivy:ignore:avd-git-0001 Repository is public
  github_repositories_existing = {
    # keep-sorted start block=yes
    "action_my_broken_link_checker" = {
      name                   = "action-my-broken-link-checker"
      description            = "A GitHub Action for checking broken links"
      topics                 = ["actions", "broken-links", "checker", "github-action", "github-actions", "link-checker", "link-checking", "links", "public", "url-checker", "url-checking", "website"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "action_my_markdown_link_checker" = {
      name                   = "action-my-markdown-link-checker"
      description            = "A GitHub Action for checking broken links in Markdown files"
      topics                 = ["actions", "broken-links", "checker", "github-action", "github-actions", "link-checker", "link-checking", "links", "markdown", "public", "url-checker", "url-checking", "website"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "action_my_markdown_linter" = {
      name                   = "action-my-markdown-linter"
      description            = "Style checking and linting for Markdown files"
      topics                 = ["github-action", "github-actions", "lint", "linter", "linting", "linters", "markdown", "public"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "ansible_my_workstation" = {
      name                   = "ansible-my_workstation"
      description            = "Ansible playbooks to configure my workstation base on Fedora / macOS"
      topics                 = ["ansible", "ansible-playbook", "configuration", "fedora", "macos", "public", "workstation"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "ansible_openwrt" = {
      name                   = "ansible-openwrt"
      description            = "Ansible playbooks configuring Openwrt devices (Wi-Fi routers)"
      topics                 = ["ansible", "ansible-playbook", "openwrt", "public", "router", "wifi"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "ansible_raspberry_pi_os" = {
      name                   = "ansible-raspberry-pi-os"
      description            = "Configure Raspberry Pi OS (RPi) using Ansible"
      topics                 = ["ansible", "grafana", "kodi", "node-exporter", "public", "prometheus", "raspberry-pi", "raspberry-pi-os", "rpi"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "cheatsheet_atom" = {
      name                   = "cheatsheet-atom"
      description            = "Atom Keyboard Shortcuts Cheatsheet"
      topics                 = ["atom", "cheatsheet", "cheatsheet-atom", "latex", "public"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "cheatsheet_macos" = {
      name                   = "cheatsheet-macos"
      description            = "MacOS Keyboard Shortcuts"
      topics                 = ["cheatsheet", "cheatsheet-mscos", "latex", "macos", "public"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "cheatsheet_systemd" = {
      name                   = "cheatsheet-systemd"
      description            = "Cheatsheet for systemd"
      topics                 = ["cheatsheet", "cheatsheet-systemd", "latex", "public", "systemd"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "cks_notes" = {
      name                   = "cks-notes"
      description            = "CKS Notes"
      topics                 = ["cks", "cks-exam", "cks-exam-preparation", "k8s", "k8s-security", "kubernetes", "public", "security"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "cv" = {
      name                   = "cv"
      description            = "My CV in LaTeX"
      visibility             = "private"
      topics                 = ["cv", "latex", "private", "resume", "texlive"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "gha_test" = {
      name                   = "gha-test"
      description            = "GitHub Action test repository"
      homepage_url           = "https://petr.ruzicka.dev"
      topics                 = ["actions", "ci", "github", "test", "github-action", "gha"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "malware_cryptominer_container" = {
      name                   = "malware-cryptominer-container"
      description            = "Container image with malware and crypto miner for testing purposes"
      homepage_url           = "https://artifacthub.io/packages/container/malware-cryptominer-container/malware-cryptominer-container"
      topics                 = ["container", "crypto", "cryptominer", "dockerfile", "eicar", "image", "malware", "public", "test", "xmrig"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "my_git_projects" = {
      name                   = "my-git-projects"
      description            = "My GitHub projects"
      topics                 = ["github", "projects", "templates"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "old_stuff" = {
      name                   = "old_stuff"
      description            = "Obsolete and old things"
      topics                 = ["bash", "perl", "old", "scripts"]
      github_actions_secrets = local.default_github_actions_secrets
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
      topics                 = ["personal", "personal-website", "public", "web", "website"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "ruzickap" = {
      name                   = "ruzickap"
      description            = "GitHub profile repository"
      topics                 = ["github", "profile"]
      github_actions_secrets = local.default_github_actions_secrets
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
      topics                 = ["blog", "github", "github-actions", "jekyll", "markdown", "personal-website", "public", "web", "website"]
      github_actions_secrets = local.default_github_actions_secrets
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
      topics                 = ["personal-site", "personal-website", "web", "website"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    "test_usb_stick_for_tv" = {
      name                   = "test_usb_stick_for_tv"
      description            = "This script will store testing videos/music/pictures to your USB Stick which can be used for testing TVs"
      topics                 = ["android-tv", "test", "testing", "testing-tools", "testing-tvs", "tv", "usb"]
      github_actions_secrets = local.default_github_actions_secrets
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
      topics                 = ["personal", "personal-website", "public", "web", "website", "xvx", "xvx-cz"]
      github_actions_secrets = local.default_github_actions_secrets
    }
    # keep-sorted end
  }
}
