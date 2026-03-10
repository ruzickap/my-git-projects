# keep-sorted start block=yes newline_separated=yes
data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_NEXT_PUBLIC_SUPABASE_ANON_KEY" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/NEXT_PUBLIC_SUPABASE_ANON_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_NEXT_PUBLIC_SUPABASE_URL" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/NEXT_PUBLIC_SUPABASE_URL"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_SUPABASE_ACCESS_TOKEN" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/SUPABASE_ACCESS_TOKEN"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_SUPABASE_DB_PASSWORD" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/SUPABASE_DB_PASSWORD"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_SUPABASE_PROJECT_REF" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/SUPABASE_PROJECT_REF"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_SUPABASE_SERVICE_ROLE_KEY" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/SUPABASE_SERVICE_ROLE_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_container_image_scans_actions_secrets_SUPABASE_URL" {
  name            = "/github/ruzickap/container-image-scans/actions-secrets/SUPABASE_URL"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_malware_cryptominer_container_actions_secrets_DOCKERHUB_CONTAINER_REGISTRY_PASSWORD" {
  name            = "/github/ruzickap/malware-cryptominer-container/actions-secrets/DOCKERHUB_CONTAINER_REGISTRY_PASSWORD"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_malware_cryptominer_container_actions_secrets_DOCKERHUB_CONTAINER_REGISTRY_USER" {
  name            = "/github/ruzickap/malware-cryptominer-container/actions-secrets/DOCKERHUB_CONTAINER_REGISTRY_USER"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_malware_cryptominer_container_actions_secrets_QUAY_CONTAINER_REGISTRY_PASSWORD" {
  name            = "/github/ruzickap/malware-cryptominer-container/actions-secrets/QUAY_CONTAINER_REGISTRY_PASSWORD"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_malware_cryptominer_container_actions_secrets_QUAY_CONTAINER_REGISTRY_USER" {
  name            = "/github/ruzickap/malware-cryptominer-container/actions-secrets/QUAY_CONTAINER_REGISTRY_USER"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_MY_AWS_AWS_ROLE_TO_ASSUME" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/MY_AWS_AWS_ROLE_TO_ASSUME"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_cloudflare_zero_trust_access_identity_provider_google_oauth_client_id" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/cloudflare_zero_trust_access_identity_provider_google_oauth_client_id"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_cloudflare_zero_trust_access_identity_provider_google_oauth_client_secret" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/cloudflare_zero_trust_access_identity_provider_google_oauth_client_secret"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_gh_token_opentofu_cloudflare_github" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/gh_token_opentofu_cloudflare_github"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_opentofu_cloudflare_github_api_token" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/opentofu_cloudflare_github_api_token"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_my_git_projects_actions_secrets_uptimerobot_api_key" {
  name            = "/github/ruzickap/my-git-projects/actions-secrets/uptimerobot_api_key"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_pre_commit_wizcli_actions_secrets_WIZ_CLIENT_ID" {
  name            = "/github/ruzickap/pre-commit-wizcli/actions-secrets/WIZ_CLIENT_ID"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_pre_commit_wizcli_actions_secrets_WIZ_CLIENT_SECRET" {
  name            = "/github/ruzickap/pre-commit-wizcli/actions-secrets/WIZ_CLIENT_SECRET"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_ruzickap_github_io_actions_secrets_GOOGLE_CLIENT_ID" {
  name            = "/github/ruzickap/ruzickap.github.io/actions-secrets/GOOGLE_CLIENT_ID"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_ruzickap_github_io_actions_secrets_GOOGLE_CLIENT_SECRET" {
  name            = "/github/ruzickap/ruzickap.github.io/actions-secrets/GOOGLE_CLIENT_SECRET"
  with_decryption = true
}

data "aws_ssm_parameter" "github_ruzickap_ruzickap_github_io_actions_secrets_MY_ATLASSIAN_PERSONAL_TOKEN" {
  name            = "/github/ruzickap/ruzickap.github.io/actions-secrets/MY_ATLASSIAN_PERSONAL_TOKEN"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_MY_RENOVATE_GITHUB_APP_ID" {
  name            = "/github/shared/actions-secrets/MY_RENOVATE_GITHUB_APP_ID"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_MY_RENOVATE_GITHUB_PRIVATE_KEY" {
  name            = "/github/shared/actions-secrets/MY_RENOVATE_GITHUB_PRIVATE_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_MY_SLACK_BOT_TOKEN" {
  name            = "/github/shared/actions-secrets/MY_SLACK_BOT_TOKEN"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_MY_SLACK_CHANNEL_ID" {
  name            = "/github/shared/actions-secrets/MY_SLACK_CHANNEL_ID"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_RUZICKA_SBX01_AWS_ROLE_TO_ASSUME" {
  name            = "/github/shared/actions-secrets/RUZICKA_SBX01_AWS_ROLE_TO_ASSUME"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_WIFI_PASSWORD" {
  name            = "/github/shared/actions-secrets/WIFI_PASSWORD"
  with_decryption = true
}

data "aws_ssm_parameter" "github_shared_actions_secrets_WIFI_SSID" {
  name            = "/github/shared/actions-secrets/WIFI_SSID"
  with_decryption = true
}
# keep-sorted end
