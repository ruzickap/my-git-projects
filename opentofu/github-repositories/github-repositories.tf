################################################################################
# Import existing GitHub Repositories
################################################################################

import {
  for_each = local.github_repositories_existing
  id       = each.value.name
  to       = github_repository.this[each.key]
}

resource "github_repository" "this" {
  for_each               = merge(local.github_repositories_existing, local.github_repositories)
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
  visibility             = try(each.value.visibility, "public")
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

# keep-sorted start block=yes

resource "github_actions_secret" "my_renovate_github_app_id" {
  for_each        = github_repository.this
  repository      = each.value.name
  secret_name     = "MY_RENOVATE_GITHUB_APP_ID"
  plaintext_value = var.my_renovate_github_app_id
}
resource "github_actions_secret" "my_renovate_github_private_key" {
  for_each        = github_repository.this
  repository      = each.value.name
  secret_name     = "MY_RENOVATE_GITHUB_PRIVATE_KEY"
  plaintext_value = var.my_renovate_github_private_key
}
resource "github_actions_secret" "my_slack_bot_token" {
  for_each        = github_repository.this
  repository      = each.value.name
  secret_name     = "MY_SLACK_BOT_TOKEN"
  plaintext_value = var.my_slack_bot_token
}
resource "github_actions_secret" "my_slack_channel_id" {
  for_each        = github_repository.this
  repository      = each.value.name
  secret_name     = "MY_SLACK_CHANNEL_ID"
  plaintext_value = var.my_slack_channel_id
}
# keep-sorted end

import {
  for_each = local.github_repositories_existing
  id       = each.value.name
  to       = github_repository_topics.this[each.key]
}

resource "github_repository_topics" "this" {
  for_each   = local.github_repositories_existing
  repository = each.value.name
  topics     = try(each.value.topics, [])
}

resource "github_repository_ruleset" "main" {
  for_each    = { for k, v in local.github_repositories_existing : k => v if try(v.visibility != "private", true) }
  name        = "main"
  repository  = each.value.name
  target      = "branch"
  enforcement = "active"

  # My Renovate App
  bypass_actors {
    actor_id   = 199026
    actor_type = "Integration"
    # Need direct access for renovate to work
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
        context = "mega-linter"
      }
    }
  }
}
