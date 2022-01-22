terraform {
  required_version = "~> 1"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4"
    }
  }
}

################################################################################
# Providers
################################################################################

provider "github" {}

################################################################################
# GitHub Repository
################################################################################

resource "github_repository" "repository" {
  name                   = "test-repo"
  description            = "🤖 This repo was auto-generated with Terraform 🤖"
  topics                 = ["blog", "database", "reports", "plugin"]
  homepage_url           = "https://petr.ruzicka.dev"
  has_wiki               = false
  has_projects           = false
  allow_merge_commit     = false
  delete_branch_on_merge = true
  auto_init              = true
  license_template       = "apache-2.0"
  visibility             = "public"
  vulnerability_alerts   = "true"
}
