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

variable "repository" {
  description = "GitHub repository which will be created"
  type        = string
  default     = "test123"
}

locals {
  repo_labels = [
    {
      name        = "size/XS",
      color       = "3CBF00",
      description = "Denotes a PR that changes 0-9 lines."
    },
    {
      name        = "size/S",
      color       = "5D9801",
      description = "Denotes a PR that changes 10-29 lines."
    },
    {
      name        = "size/M",
      color       = "7F7203",
      description = "Denotes a PR that changes 30-99 lines."
    },
    {
      name        = "size/L",
      color       = "A14C05",
      description = "Denotes a PR that changes 100-499 lines."
    },
    {
      name        = "size/XL",
      color       = "C32607",
      description = "Denotes a PR that changes 500-999 lines."
    },
    {
      name        = "size/XXL",
      color       = "E50009",
      description = "Denotes a PR that changes 1000+ lines."
    },
  ]
}

resource "github_repository" "repository" {
  name                   = var.repository
  description            = "Repository for building container to help manage RAW photos"
  topics                 = ["container", "dockerfile", "darktable-cli", "exiftool", "raw", "photo", "tools", "manage"]
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

resource "github_issue_label" "repository" {
  for_each = { for label in local.repo_labels : label.name => label }

  repository  = var.repository
  name        = each.value.name
  color       = each.value.color
  description = each.value.description
}
