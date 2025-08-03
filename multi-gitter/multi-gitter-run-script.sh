#!/usr/bin/env bash

set -euo pipefail

# Configuration
GH_REPO_DEFAULTS_BASE="${GH_REPO_DEFAULTS_BASE:-${HOME}/git/my-git-projects/gh-repo-defaults}"

# Simple logging
log() { echo "[$(date +'%H:%M:%S')] $*" >&2; }
die() {
  log "ERROR: $*"
  exit 1
}

# Validation
[[ -n "${REPOSITORY:-}" ]] || die "REPOSITORY environment variable required"
[[ -d "$GH_REPO_DEFAULTS_BASE" ]] || die "Defaults directory not found: $GH_REPO_DEFAULTS_BASE"
command -v rclone > /dev/null || die "rclone not found"
command -v git > /dev/null || die "git not found"

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
  for FILE in "$@"; do
    if git checkout "$FILE" 2> /dev/null; then
      log "Checked out: $FILE"
    else
      log "Skipped: $FILE"
    fi
  done
}

remove_files() {
  for FILE in "$@"; do
    [[ -f "$FILE" ]] && rm "$FILE" && log "Removed: $FILE"
  done
}

# Main processing
log "Processing $REPOSITORY"

# Always copy base defaults
copy_defaults "$GH_REPO_DEFAULTS_BASE/my-defaults"

# Repository-specific handling
case "$REPOSITORY" in
  ruzickap/action-*)
    copy_defaults "$GH_REPO_DEFAULTS_BASE/action"
    ;;
  ruzickap/ansible-*)
    copy_defaults "$GH_REPO_DEFAULTS_BASE/ansible"
    [[ "$REPOSITORY" == "ruzickap/ansible-raspberry-pi-os" ]] && checkout_files "ansible/.ansible-lint"
    ;;
  ruzickap/cheatsheet-*)
    copy_defaults "$GH_REPO_DEFAULTS_BASE/latex"
    ;;
  ruzickap/cv)
    copy_defaults "$GH_REPO_DEFAULTS_BASE/latex"
    checkout_files "run.sh"
    remove_files ".github/workflows/codeql-actions.yml" ".github/workflows/scorecards.yml"
    ;;
  ruzickap/petr.ruzicka.dev|ruzickap/xvx.cz)
    copy_defaults "$GH_REPO_DEFAULTS_BASE/hugo"
    checkout_files ".spelling"
    ;;
  ruzickap/malware-cryptominer-container)
    checkout_files ".checkov.yml" ".github/workflows/release-please.yml" ".github/renovate.json5"
    ;;
  ruzickap/ruzickap.github.io)
    checkout_files ".github/renovate.json5" ".github/workflows/mega-linter.yml" ".markdownlint.yml" ".mega-linter.yml"
    ;;
  *)
    log "Using default configuration for $REPOSITORY"
    ;;
esac

log "Completed processing $REPOSITORY"
