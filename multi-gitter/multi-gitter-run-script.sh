#!/usr/bin/env bash

#===============================================================================
# Multi-Gitter Repository Update Script
#
# This script is used with multi-gitter to update multiple repositories with
# standardized configuration files and settings.
#
# Usage: Called automatically by multi-gitter with REPOSITORY environment variable
# Requirements: rclone, git
#===============================================================================

set -euxo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly GH_REPO_DEFAULTS_BASE="${GH_REPO_DEFAULTS_BASE:-${HOME}/git/my-git-projects/gh-repo-defaults}"
readonly RCLONE_OPTS="${RCLONE_OPTS:---verbose --stats 0}"

# Logging functions
log_info() {
  echo -e "\n[INFO] $*" >&2
}

log_error() {
  echo -e "\n[ERROR] $*" >&2
}

log_section() {
  echo -e "\n***************************************************"
  echo -e "* $*"
  echo -e "***************************************************\n"
}

# Validation functions
validate_environment() {
  if [[ -z "${REPOSITORY:-}" ]]; then
    log_error "REPOSITORY environment variable is required"
    exit 1
  fi

  if [[ ! -d "${GH_REPO_DEFAULTS_BASE}" ]]; then
    log_error "GitHub repo defaults directory not found: ${GH_REPO_DEFAULTS_BASE}"
    exit 1
  fi

  # Check required commands
  for cmd in rclone git; do
    if ! command -v "$cmd" &> /dev/null; then
      log_error "Required command not found: $cmd"
      exit 1
    fi
  done
}

# Core functions
copy_defaults() {
  local source_dir="$1"
  local description="${2:-${source_dir##*/}}"

  if [[ ! -d "$source_dir" ]]; then
    log_error "Source directory not found: $source_dir"
    return 1
  fi

  log_info "$description | ${REPOSITORY}"
  if ! rclone copyto ${RCLONE_OPTS} "$source_dir" .; then
    log_error "Failed to copy from: $source_dir"
    return 1
  fi
}

checkout_files() {
  local files=("$@")
  log_info "Checking out specific files for ${REPOSITORY}"

  for file in "${files[@]}"; do
    if ! git checkout "$file" 2>/dev/null; then
      log_info "Could not checkout $file (may not exist)"
    fi
  done
}

remove_files() {
  local files=("$@")
  log_info "Removing files for ${REPOSITORY}"

  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      rm "$file"
      log_info "Removed: $file"
    fi
  done
}

# Repository type handlers
handle_action_repos() {
  copy_defaults "${GH_REPO_DEFAULTS_BASE}/action" "action"
}

handle_ansible_repos() {
  copy_defaults "${GH_REPO_DEFAULTS_BASE}/ansible" "ansible"

  # Special handling for specific ansible repos
  case "${REPOSITORY}" in
    ruzickap/ansible-raspberry-pi-os)
      checkout_files "ansible/.ansible-lint"
      ;;
  esac
}

handle_latex_repos() {
  copy_defaults "${GH_REPO_DEFAULTS_BASE}/latex" "latex"

  # Special handling for CV repo
  case "${REPOSITORY}" in
    ruzickap/cv)
      checkout_files "run.sh"
      remove_files ".github/workflows/codeql-actions.yml" ".github/workflows/scorecards.yml"
      ;;
  esac
}

handle_hugo_repos() {
  copy_defaults "${GH_REPO_DEFAULTS_BASE}/hugo" "hugo"

  # Special handling for xvx.cz
  case "${REPOSITORY}" in
    ruzickap/xvx.cz)
      checkout_files ".spelling"
      ;;
  esac
}

handle_special_repos() {
  case "${REPOSITORY}" in
    ruzickap/malware-cryptominer-container)
      checkout_files ".checkov.yml" ".github/workflows/release-please.yml" ".github/renovate.json5"
      ;;
    ruzickap/ruzickap.github.io)
      checkout_files ".github/renovate.json5" ".github/workflows/mega-linter.yml" ".markdownlint.yml" ".mega-linter.yml"
      ;;
  esac
}

# Main processing function
process_repository() {
  log_section "${REPOSITORY}"

  # Always copy base defaults first
  copy_defaults "${GH_REPO_DEFAULTS_BASE}/my-defaults" "my-defaults"

  # Process based on repository pattern/name
  case "${REPOSITORY}" in
    ruzickap/action-*)
      handle_action_repos
      ;;
    ruzickap/ansible-*)
      handle_ansible_repos
      ;;
    ruzickap/cheatsheet-* | ruzickap/cv)
      handle_latex_repos
      ;;
    ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
      handle_hugo_repos
      ;;
    *)
      log_info "Using default configuration for ${REPOSITORY}"
      ;;
  esac

  # Handle repositories with special requirements
  handle_special_repos

  log_info "Processing completed for ${REPOSITORY}"
}

# Main execution
main() {
  validate_environment

  if [[ "${DEBUG:-false}" == "true" ]]; then
    set -x
  fi

  process_repository
}

# Execute main function
main "$@"
