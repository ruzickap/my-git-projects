terraform {
  required_version = "~> 1.5"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6"
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
# GitHub Repository
################################################################################

# trivy:ignore:AVD-GIT-0001
resource "github_repository" "repository" {
  # checkov:skip=CKV_GIT_1:Ensure GitHub repository is Private
  # checkov:skip=CKV2_GIT_1:Ensure each Repository has branch protection associated
  allow_merge_commit     = false
  allow_update_branch    = true
  auto_init              = true
  delete_branch_on_merge = true
  description            = "K8s Hacking Notes"
  # gitignore_template     = "Terraform"
  has_issues           = true
  has_projects         = false
  has_wiki             = false
  homepage_url         = "https://petr.ruzicka.dev"
  license_template     = "apache-2.0"
  name                 = "k8s-hacking-notes"
  topics               = ["k8s", "hacking", "notes"]
  visibility           = "public"
  vulnerability_alerts = true
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}

# # This is not working with Renovate automerge - PR is always created...
# resource "github_branch_protection" "repository" {
#   repository_id          = github_repository.repository.node_id
#   pattern                = "main"
#   require_signed_commits = true
#   allows_deletions       = true

#   required_pull_request_reviews {
#     required_approving_review_count = 0
#     dismiss_stale_reviews           = true
#   }
# }

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

################################################################################
# Outputs
################################################################################

output "github_ssh_clone_url" {
  description = "GitHub SSH Clone URL"
  value       = github_repository.repository.ssh_clone_url
}

output "github_ssh_clone_url_commands" {
  description = "GitHub SSH Clone URL Commands"
  value       = github_repository.repository.ssh_clone_url
}
