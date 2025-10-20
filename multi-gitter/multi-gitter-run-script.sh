#!/usr/bin/env bash

set -euo pipefail

# Configuration
GH_REPO_DEFAULTS_BASE="${GH_REPO_DEFAULTS_BASE:-${HOME}/git/my-git-projects/gh-repo-defaults}"

# Simple logging
log() { echo "[$(date +'%H:%M:%S')] ${*}" >&2; }
log_info() { log "INFO: ${*}"; }
log_error() { log "ERROR: ${*}"; }
die() {
  log_error "${*}"
  exit 1
}

# Validation
[[ -n "${REPOSITORY:-}" ]] || die "REPOSITORY environment variable required"
[[ -d "${GH_REPO_DEFAULTS_BASE}" ]] || die "Defaults directory not found: ${GH_REPO_DEFAULTS_BASE}"
command -v rclone > /dev/null || die "rclone not found"
command -v git > /dev/null || die "git not found"

# Core functions
copy_defaults() {
  local SOURCE_DIR="${1}"
  local DESCRIPTION="${2:-${SOURCE_DIR##*/}}"

  if [[ ! -d "${SOURCE_DIR}" ]]; then
    log "ERROR: Source directory not found: ${SOURCE_DIR}"
    return 1
  fi

  log_info "${DESCRIPTION} | ${REPOSITORY}"
  if ! rclone copyto --verbose --stats 0 "${SOURCE_DIR}" .; then
    log_error "Failed to copy from: ${SOURCE_DIR}"
    return 1
  fi
}

checkout_files() {
  for FILE in "${@}"; do
    if git checkout "${FILE}" 2> /dev/null; then
      log_info "Checked out: ${FILE}"
    else
      log_info "Skipped: ${FILE}"
    fi
  done
}

remove_files() {
  for FILE in "${@}"; do
    [[ -f "${FILE}" ]] && rm "${FILE}" && log_info "Removed: ${FILE}"
  done
}

# Main processing
log_info "Processing ${REPOSITORY}"

# Always copy base defaults
copy_defaults "${GH_REPO_DEFAULTS_BASE}/my-defaults"

# Repository-specific handling
case "${REPOSITORY}" in
  ruzickap/action-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/action"
    ;;
  ruzickap/ansible-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/ansible"
    ;;
  ruzickap/cheatsheet-*)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/latex"
    ;;
  ruzickap/cv)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/latex"
    checkout_files "run.sh"
    remove_files ".github/workflows/codeql.yml" ".github/workflows/scorecards.yml"
    ;;
  ruzickap/gha_test)
    remove_files ".github/workflows/pr-slack-notification.yml"
    ;;
  ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
    copy_defaults "${GH_REPO_DEFAULTS_BASE}/hugo"
    checkout_files ".spelling"
    ;;
  ruzickap/malware-cryptominer-container)
    checkout_files ".checkov.yml" ".github/workflows/release-please.yml" ".github/renovate.json5"
    ;;
  ruzickap/ruzickap.github.io)
    checkout_files ".github/renovate.json5" ".github/workflows/mega-linter.yml" ".markdownlint.yml" ".mega-linter.yml"
    ;;
  *)
    log_info "Using default configuration for ${REPOSITORY}"
    ;;
esac

log_info "Completed processing ${REPOSITORY}"
