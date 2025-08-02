################################################################################
# Import existing GitHub Repositories
################################################################################

import {
  for_each = local.github_repositories_existing
  id       = each.value.name
  to       = github_repository.this[each.key]
}

resource "github_repository" "this" {
  #checkov:skip=CKV_GIT_1:Ensure GitHub repository is Private
  #checkov:skip=CKV2_GIT_1:Ensure each Repository has branch protection associated
  for_each               = local.all_github_repositories
  allow_merge_commit     = false
  allow_update_branch    = true
  auto_init              = true
  delete_branch_on_merge = true
  description            = try(each.value.description, "")
  has_discussions        = try(each.value.has_discussions, false)
  has_issues             = true
  has_projects           = false
  has_wiki               = false
  homepage_url           = try(each.value.homepage_url, "")
  license_template       = "apache-2.0"
  name                   = each.value.name
  visibility             = try(each.value.visibility, "public") #trivy:ignore:AVD-GIT-0001
  vulnerability_alerts   = true

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

locals {
  # Define all secrets to be created for each repository
  github_actions_secrets = {
    "MY_RENOVATE_GITHUB_APP_ID"      = var.my_renovate_github_app_id
    "MY_RENOVATE_GITHUB_PRIVATE_KEY" = var.my_renovate_github_private_key
    "MY_SLACK_BOT_TOKEN"             = var.my_slack_bot_token
    "MY_SLACK_CHANNEL_ID"            = var.my_slack_channel_id
  }
}

resource "github_actions_secret" "this" {
  for_each = {
    for combo in setproduct(keys(local.all_github_repositories), keys(local.github_actions_secrets)) :
    "${combo[0]}-${combo[1]}" => {
      repository   = local.all_github_repositories[combo[0]].name
      secret_name  = combo[1]
      secret_value = local.github_actions_secrets[combo[1]]
    }
  }
  repository      = each.value.repository
  secret_name     = each.value.secret_name
  plaintext_value = each.value.secret_value
}

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
  bypass_actors {
    actor_id   = 199026
    actor_type = "Integration"
    # Needs direct access for Renovate to work
    bypass_mode = "always"
  }
  # Repository admin
  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }
  conditions {
    ref_name {
      exclude = []
      include = ["~DEFAULT_BRANCH"]
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    # required_signatures     = true
    pull_request {
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_approving_review_count   = 2
      required_review_thread_resolution = true
    }
    required_status_checks {
      strict_required_status_checks_policy = true
      required_check {
        context = "semantic-pull-request"
      }
    }
  }
}
