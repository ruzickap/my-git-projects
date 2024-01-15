terraform {
  required_version = "~> 1.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5"
    }
  }
}

################################################################################
# Providers
################################################################################

provider "github" {}

################################################################################
# Variables
################################################################################

variable "my_renovate_github_app_id" {
  type        = string
  sensitive   = true
  description = "My Renovate GitHub Application app id"
}

variable "my_renovate_github_private_key" {
  type        = string
  sensitive   = true
  description = "My Renovate GitHub Application private key"
}

################################################################################
# Variables
################################################################################

locals {
  github_repository_default_files = [
    ".github/CODEOWNERS",
    ".github/ISSUE_TEMPLATE/bug_report.md",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/ISSUE_TEMPLATE/proposal.md",
    ".github/renovate.json5",
    ".github/workflows/mega-linter.yml",
    ".github/workflows/release-please.yml",
    ".github/workflows/renovate.yml",
    ".github/workflows/semantic-pull-request.yml",
    ".github/workflows/stale.yml",
  ]
}

################################################################################
# GitHub Repository
################################################################################

resource "github_repository" "repository" {
  allow_merge_commit     = false
  allow_update_branch    = true
  auto_init              = true
  delete_branch_on_merge = true
  description            = "Multicloud+Multitenant+Multicluster Managed K8s Cluster installation using OpenTofu, GitHub Actions and ArgoCD"
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  homepage_url           = "https://petr.ruzicka.dev"
  license_template       = "apache-2.0"
  name                   = "k8s-tf-gitops"
  topics                 = ["opentofu", "eks", "aks", "argocd", "multicluster", "multitenant", "k8s", "gitops", "multicloud", "github-actions"]
  visibility             = "public"
  vulnerability_alerts   = true
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}

resource "github_branch_protection" "repository" {
  repository_id          = github_repository.repository.node_id
  pattern                = "main"
  require_signed_commits = true
  allows_deletions       = true

  required_pull_request_reviews {
    required_approving_review_count = 0
    dismiss_stale_reviews           = true
  }
}

resource "github_actions_secret" "my_renovate_github_app_id" {
  repository      = github_repository.repository.id
  secret_name     = "MY_RENOVATE_GITHUB_APP_ID"
  plaintext_value = var.my_renovate_github_app_id
}

resource "github_actions_secret" "my_renovate_github_private_key" {
  repository      = github_repository.repository.id
  secret_name     = "MY_RENOVATE_GITHUB_PRIVATE_KEY"
  plaintext_value = var.my_renovate_github_private_key
}

resource "github_repository_file" "github-files" {
  # for_each   = local.github_repository_default_files
  # for_each   = { for file in local.github_repository_default_files : file.name => file}
  for_each   = toset(local.github_repository_default_files)
  file       = each.value
  repository = github_repository.repository.name
  content    = file("../${each.value}")
}

################################################################################
# Outputs
################################################################################

output "github_ssh_clone_url" {
  description = "GitHub SSH Clone URL"
  value       = github_repository.repository.ssh_clone_url
}
