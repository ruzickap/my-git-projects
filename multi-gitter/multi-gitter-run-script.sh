#!/usr/bin/env bash

set -euo pipefail

# Configuration
GH_REPO_DEFAULTS_BASE="${GH_REPO_DEFAULTS_BASE:-${HOME}/git/my-git-projects/gh-repo-defaults}"

# Simple logging
log() { echo "[$(date +'%H:%M:%S')] ${*}" >&2; }
log_info() { log "❇️ INFO: ${*}"; }
log_error() { log "❌ ERROR: ${*}"; }
die() {
  log_error "${*}"
  exit 1
}

# Validation
[[ -n "${REPOSITORY:-}" ]] || die "REPOSITORY environment variable required"
[[ -d "${GH_REPO_DEFAULTS_BASE}" ]] || die "Defaults directory not found: ${GH_REPO_DEFAULTS_BASE}"
command -v gh > /dev/null || die "gh not found"
command -v rclone > /dev/null || die "rclone not found"
command -v git > /dev/null || die "git not found"

# Core functions
copy_defaults() {
  local SOURCE_DIR="${1}"

  if [[ ! -d "${SOURCE_DIR}" ]]; then
    log_error "Source directory not found: ${SOURCE_DIR}"
    return 1
  fi

  log_info "${SOURCE_DIR##*/} | ${REPOSITORY}"
  if ! rclone copyto --verbose --stats 0 --no-update-modtime --no-update-dir-modtime --exclude AGENTS.md "${SOURCE_DIR}" .; then
    log_error "Failed to copy from: ${SOURCE_DIR}"
    return 1
  fi
}

checkout_files() {
  for FILE in "${@}"; do
    if git checkout "${FILE}" 2> /dev/null; then
      log_info "Checked out: ${FILE}"
    else
      log_error "Skipped: ${FILE}"
    fi
  done
}

remove_files() {
  for FILE in "${@}"; do
    [[ -f "${FILE}" ]] && rm "${FILE}" && log_info "Removed: ${FILE}"
  done
}

private_repository() {
  if gh repo view "${REPOSITORY}" --json isPrivate --jq '.isPrivate' 2> /dev/null | grep -q "true"; then
    log_info "Private repository detected: ${REPOSITORY}"
    remove_files ".github/workflows/codeql.yml" ".github/workflows/scorecards.yml"
    sed -i -E '/^[[:space:]]*schedule:[[:space:]]*$/ { N; /^[[:space:]]*schedule:[[:space:]]*\n[[:space:]]*-[[:space:]]*cron:[[:space:]]*.*$/d; }' .github/workflows/*.yml
  fi
}

megalinter_flavor() {
  local FLAVOR="${1}"
  local MEGALINTER_FILE=".github/workflows/mega-linter.yml"
  local REPLACEMENT="oxsecurity/megalinter/flavors/${FLAVOR}"

  if [[ ! -f "${MEGALINTER_FILE}" ]]; then
    log_error "MegaLinter workflow not found: ${MEGALINTER_FILE} !"
    return 1
  fi

  [[ "${FLAVOR}" == "all" ]] && REPLACEMENT="oxsecurity/megalinter"

  sed -i "s@uses: oxsecurity/megalinter/flavors/documentation@uses: ${REPLACEMENT}@" "${MEGALINTER_FILE}"
  log_info "Set MegaLinter flavor to: ${FLAVOR}"
}

# Main processing
log_info "👉 Processing ${REPOSITORY}"

# Always copy base defaults
copy_defaults "${GH_REPO_DEFAULTS_BASE}/my-defaults"
sed -i "s@/ruzickap/my-git-projects/@/${REPOSITORY}/@" ".github/ISSUE_TEMPLATE/config.yml"

# Remove code not applicable to private repositories
private_repository

# Upgrade all in GH Actions
actions-up --yes --min-age 3

# Repository-specific handling
case "${REPOSITORY}" in
  ruzickap/action-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/action"
    ;;
  ruzickap/ansible-raspberry-pi-os)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/ansible"
    megalinter_flavor all
    ;;
  ruzickap/ansible-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/ansible"
    ;;
  ruzickap/brewwatch)
    checkout_files ".mega-linter.yml"
    megalinter_flavor all
    ;;
  ruzickap/cheatsheet-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/latex"
    megalinter_flavor all
    ;;
  ruzickap/cv)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/latex"
    checkout_files "run.sh" # Disable SVG
    megalinter_flavor all
    ;;
  ruzickap/gha_test)
    remove_files ".github/workflows/pr-slack-notification.yml"
    ;;
  ruzickap/k8s-multicluster-gitops)
    megalinter_flavor cupcake
    ;;
  ruzickap/malware-cryptominer-container)
    checkout_files ".checkov.yml" ".github/workflows/release-please.yml" ".github/renovate.json5"
    megalinter_flavor cupcake
    ;;
  ruzickap/my-git-projects)
    megalinter_flavor cupcake
    ;;
  ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/hugo"
    ;;
  ruzickap/pre-commit-wizcli)
    megalinter_flavor cupcake
    ;;
  ruzickap/ruzickap.github.io)
    checkout_files ".github/renovate.json5" ".rumdl.toml" ".mega-linter.yml" "AGENTS.md"
    megalinter_flavor ruby
    ;;
  *)
    log_info "Using default configuration for ${REPOSITORY}"
    ;;
esac

# # Remove after first init/run
# log_info "Copying AGENTS.md from defaults and reinitializing with opencode"
# cp "${GH_REPO_DEFAULTS_BASE}/my-defaults/AGENTS.md" AGENTS.md
# opencode run --model="github-copilot/claude-opus-4.6" --command "init"

# # Handle AGENTS.md: copy if missing, reinitialize if identical to default
# if [[ ! -f "AGENTS.md" ]]; then
#   log_info "Copying AGENTS.md from defaults and reinitializing with opencode"
#   cp "${GH_REPO_DEFAULTS_BASE}/my-defaults/AGENTS.md" AGENTS.md
#   opencode run --model="github-copilot/claude-opus-4.6" --command "init"
# fi

log_info "Completed processing ${REPOSITORY}"
