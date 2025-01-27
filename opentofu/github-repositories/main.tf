terraform {
  backend "s3" {
    bucket                      = "ruzickap-my-git-projects-opentofu-state-file"
    key                         = "ruzickap-my-git-projects-opentofu-state-file.tfstate"
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
  required_version = "~> 1.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {}

locals {
  github_repositories = {
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
      topics      = ["github-action", "github-actions", "lint", "linter", "linting", "linters", "markdown"]
    }
    "ansible_my_workstation" = {
      name        = "ansible-my_workstation"
      description = "Ansible playbooks to configure my workstation base on Fedora / macOS"
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
    }
    "ansible_role_my_common_defaults" = {
      name        = "ansible-role-my_common_defaults"
      description = "My Ansible role which sets some \"favorite\" defaults on the server (CentOS / Ubuntu / Windows)"
      topics      = ["ansible", "ansible-role", "centos", "debian", "public", "redhat", "ubuntu", "windows"]
    }
    "ansible_role_proxy_settings" = {
      name         = "ansible-role-proxy_settings"
      description  = "Ansible role for configuring proxy settings for Linux based systems"
      homepage_url = "https://galaxy.ansible.com/ruzickap/proxy_settings/"
      topics       = ["ansible", "ansible-role", "debian", "proxy", "proxy-settings", "public", "redhat", "ubuntu"]
    }
    "ansible_role_virtio_win" = {
      name        = "ansible-role-virtio-win"
      description = "Ansible role which installs VirtIO Drivers and SPICE Guest Tools for Windows"
      topics      = ["ansible", "ansible-role", "public", "spice-guest", "virtio", "virtio-drivers", "windows"]
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
      topics      = ["cks", "cks-exam", "cks-exam-preparation", "k8s", "k8s-security", "kubernetes", "public", "security"]
    }
    "cv" = {
      name        = "cv"
      description = "My CV in LaTeX"
      visibility  = "private"
      topics      = ["cv", "latex", "private", "resume", "texlive"]
    }
    "gha_test" = {
      name         = "gha-test"
      description  = "GitHub Action test repository"
      homepage_url = "https://petr.ruzicka.dev"
      topics       = ["actions", "ci", "github", "test", "github-action", "gha"]
    }
    "malware_cryptominer_container" = {
      name         = "malware-cryptominer-container"
      description  = "Container image with malware and crypto miner for testing purposes"
      homepage_url = "https://artifacthub.io/packages/container/malware-cryptominer-container/malware-cryptominer-container"
      topics       = ["container", "crypto", "cryptominer", "dockerfile", "eicar", "image", "malware", "public", "test", "xmrig"]
    }
    "my_git_projects" = {
      name        = "my-git-projects"
      description = "My GitHub projects"
      topics      = ["github", "projects", "public", "templates"]
    }
    "old_stuff" = {
      name        = "old_stuff"
      description = "Obsolete and old things"
      topics      = ["bash", "perl", "old", "scripts"]
    }
    "packer_templates" = {
      name            = "packer-templates"
      description     = "Scripts and Templates used for generating Vagrant images"
      has_discussions = true
      topics          = ["ansible", "driver", "libvirt", "linux", "packer-template", "packer-templates", "packer", "public", "qemu", "templates", "vagrant", "vagrant-plugins", "vagrant", "virtio", "virtualbox", "windows"]
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
    }
    "ruzickap" = {
      name        = "ruzickap"
      description = "GitHub profile repository"
      topics      = ["github", "profile", "public"]
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
      description = "This script will store testing videos/music/pictures to your USB Stick which can be used for testing TVs"
      topics      = ["android-tv", "public", "test", "testing", "testing-tools", "testing-tvs", "tv", "usb"]
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
    }
    # keep-sorted end
  }
}
