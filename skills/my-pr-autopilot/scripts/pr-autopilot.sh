#!/usr/bin/env bash
# Helper for driving a GitHub pull request to green CI and a Copilot review.
#
# Usage:
#   pr-autopilot.sh wait-checks  [PR]  # wait for CI to finish
#   pr-autopilot.sh failed-logs  [PR]  # tail logs of failing Actions jobs
#   pr-autopilot.sh wait-copilot [PR]  # wait for Copilot review of the PR
#
# PR can be a number or URL; defaults to the PR of the current branch.
#
# Exit codes:
#   wait-checks:  0 all passed, 1 failed/cancelled, 2 timeout, 3 no checks
#   wait-copilot: 0 reviewed, 2 timeout, 3 Copilot was never requested
#
# Tunables (env, seconds): CHECKS_TIMEOUT=3600 CHECKS_APPEAR_TIMEOUT=300
# CHECKS_MIN_WAIT=60 COPILOT_REQUEST_TIMEOUT=120 COPILOT_REVIEW_TIMEOUT=1200
# POLL_INTERVAL=30 LOG_LINES=150 (lines per failed job)

set -euo pipefail

: "${CHECKS_TIMEOUT:=3600}"
: "${CHECKS_APPEAR_TIMEOUT:=300}"
: "${CHECKS_MIN_WAIT:=60}"
: "${COPILOT_REQUEST_TIMEOUT:=120}"
: "${COPILOT_REVIEW_TIMEOUT:=1200}"
: "${POLL_INTERVAL:=30}"
: "${LOG_LINES:=150}"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

log() {
  printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2
}

# gh pr checks exits non-zero when checks fail or are pending, so the exit
# code is ignored. Prints [] only when gh says there are no checks; any other
# non-JSON output is an error (network, auth, API) and returns 1.
get_checks() {
  local CHECKS
  CHECKS=$(gh pr checks "${PR_URL}" --json name,state,bucket,link,workflow 2>&1 || true)
  if jq -e 'type == "array"' <<< "${CHECKS}" > /dev/null 2>&1; then
    printf '%s\n' "${CHECKS}"
  elif grep -q 'no checks reported' <<< "${CHECKS}"; then
    echo '[]'
  else
    log "Failed to get checks: ${CHECKS}"
    return 1
  fi
}

print_checks() {
  jq -r 'sort_by(.bucket, .workflow, .name)[] | [.bucket, .workflow, .name, .link] | @tsv' <<< "$1"
}

wait_checks() {
  local START NOW CHECKS TOTAL PENDING FAILED STABLE=0
  START=$(date +%s)
  log "Waiting for CI checks on ${PR_URL}"
  while true; do
    NOW=$(date +%s)
    if ! CHECKS=$(get_checks); then
      if ((NOW - START > CHECKS_TIMEOUT)); then
        echo "RESULT: error - could not read checks for ${PR_URL}"
        return 2
      fi
      sleep "${POLL_INTERVAL}"
      continue
    fi
    TOTAL=$(jq 'length' <<< "${CHECKS}")

    if [[ "${TOTAL}" -eq 0 ]]; then
      if ((NOW - START > CHECKS_APPEAR_TIMEOUT)); then
        echo "RESULT: none - no checks reported for ${PR_URL}"
        return 3
      fi
      log "No checks reported yet"
    else
      PENDING=$(jq '[.[] | select(.bucket == "pending")] | length' <<< "${CHECKS}")
      if [[ "${PENDING}" -eq 0 ]]; then
        # Require two quiet polls and a minimum wait, so workflows that are
        # queued late (after the first ones already finished) are not missed.
        STABLE=$((STABLE + 1))
        if ((STABLE >= 2 && NOW - START >= CHECKS_MIN_WAIT)); then
          print_checks "${CHECKS}"
          FAILED=$(jq '[.[] | select(.bucket == "fail" or .bucket == "cancel")] | length' <<< "${CHECKS}")
          if [[ "${FAILED}" -gt 0 ]]; then
            echo "RESULT: fail - ${FAILED}/${TOTAL} checks failed or were cancelled"
            return 1
          fi
          echo "RESULT: pass - all ${TOTAL} checks passed or were skipped"
          return 0
        fi
      else
        STABLE=0
        log "${PENDING}/${TOTAL} checks pending"
      fi
    fi

    if ((NOW - START > CHECKS_TIMEOUT)); then
      print_checks "${CHECKS}"
      echo "RESULT: timeout - checks still pending after ${CHECKS_TIMEOUT}s"
      return 2
    fi
    sleep "${POLL_INTERVAL}"
  done
}

# Log lines are "job<TAB>step<TAB>timestamp message". Keep only the message
# and drop colour codes (raw ESC or the "^[" form gh prints).
fetch_job_log() {
  local OWNER_REPO="$1" RUN_ID="$2" JOB_ID="$3" RAW
  RAW=$(gh run view "${RUN_ID}" -R "${OWNER_REPO}" --job "${JOB_ID}" --log 2> /dev/null) || RAW=""
  [[ -n "${RAW}" ]] || return 0
  printf '%s\n' "${RAW}" | cut -f3- | perl -pe 's/^\S+Z //; s/(\e|\^\[)\[[0-9;]*m//g'
}

failed_logs() {
  local OWNER_REPO LOG_DIR LOG_FILE CHECKS END WORKFLOW NAME BUCKET LINK RUN_ID JOB_ID
  OWNER_REPO=$(sed -E 's#https://github.com/([^/]+/[^/]+)/pull/.*#\1#' <<< "${PR_URL}")
  LOG_DIR="${TMPDIR:-/tmp}"
  LOG_DIR=$(mktemp -d "${LOG_DIR%/}/pr-autopilot-logs.XXXXXX")
  CHECKS=$(get_checks)
  # "-" placeholder: read collapses empty tab-separated fields (IFS whitespace)
  jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | [(.workflow // "" | if . == "" then "-" else . end), .name, .bucket, .link] | @tsv' <<< "${CHECKS}" |
    while IFS=$'\t' read -r WORKFLOW NAME BUCKET LINK; do
      printf '\n===== %s / %s (%s)\n%s\n' "${WORKFLOW}" "${NAME}" "${BUCKET}" "${LINK}"
      if [[ ! "${LINK}" =~ /actions/runs/([0-9]+)/job/([0-9]+) ]]; then
        echo "External check (not a GitHub Actions job) - logs not available here."
        continue
      fi
      RUN_ID=${BASH_REMATCH[1]}
      JOB_ID=${BASH_REMATCH[2]}
      LOG_FILE="${LOG_DIR}/${RUN_ID}-${JOB_ID}.log"
      fetch_job_log "${OWNER_REPO}" "${RUN_ID}" "${JOB_ID}" > "${LOG_FILE}"
      echo "run_id=${RUN_ID} job_id=${JOB_ID} full_log=${LOG_FILE} ($(wc -l < "${LOG_FILE}" | tr -d ' ') lines)"
      if [[ ! -s "${LOG_FILE}" ]]; then
        echo "(could not fetch the job log - open the link above)"
        continue
      fi
      # Post-job cleanup is noise; cut the log where it starts.
      END=$(grep -n -m 1 '^Post job cleanup' "${LOG_FILE}" | cut -d: -f1 || true)
      echo "--- lines with error markers (first 40):"
      grep -n -iE '##\[error\]|error|fail|❌' "${LOG_FILE}" |
        grep -viE 'pipefail|fail[-_]on|continue-on-error|ignore-errors' | head -n 40 || true
      echo "--- last ${LOG_LINES} lines before post-job cleanup:"
      if [[ -n "${END}" ]]; then
        head -n "$((END - 1))" "${LOG_FILE}"
      else
        cat "${LOG_FILE}"
      fi | tail -n "${LOG_LINES}"
    done
}

wait_copilot() {
  local START NOW DATA REVIEW REQUESTED=0
  START=$(date +%s)
  log "Waiting for a Copilot review on ${PR_URL}"
  while true; do
    NOW=$(date +%s)
    DATA=$(gh pr view "${PR_URL}" --json headRefOid,reviewRequests,reviews)

    # A Copilot review counts only if it covers the current head commit.
    REVIEW=$(jq -c '
      .headRefOid as $HEAD
      | [.reviews[]
          | select(.author.login | ascii_downcase | test("copilot"))
          | select(.commit.oid == $HEAD)]
      | last // empty' <<< "${DATA}")
    if [[ -n "${REVIEW}" ]]; then
      echo "RESULT: reviewed"
      jq -r '"state: \(.state)\nsubmitted: \(.submittedAt)\ncommit: \(.commit.oid)\n\n\(.body)"' <<< "${REVIEW}"
      return 0
    fi

    # `gh pr view --json reviewRequests` omits Bot reviewers (Copilot), so ask GraphQL
    # shellcheck disable=SC2016
    if gh api graphql -F owner="${OWNER}" -F repo="${REPO}" -F number="${NUMBER}" -f query='
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) { pullRequest(number: $number) {
          reviewRequests(first: 50) { nodes { requestedReviewer {
            ... on Bot { login } ... on User { login } } } } } } }' \
      --jq '[.data.repository.pullRequest.reviewRequests.nodes[].requestedReviewer.login // "" | ascii_downcase | select(test("copilot"))] | length > 0' | grep -q true; then
      if [[ "${REQUESTED}" -eq 0 ]]; then
        log "Copilot review is requested, waiting for it to finish"
        REQUESTED=1
      fi
    elif [[ "${REQUESTED}" -eq 0 ]] && ((NOW - START > COPILOT_REQUEST_TIMEOUT)); then
      echo "RESULT: not-requested - Copilot is not a requested reviewer of ${PR_URL}"
      return 3
    fi

    if ((NOW - START > COPILOT_REVIEW_TIMEOUT)); then
      echo "RESULT: timeout - no Copilot review after ${COPILOT_REVIEW_TIMEOUT}s"
      return 2
    fi
    sleep "${POLL_INTERVAL}"
  done
}

COMMAND="${1:-}"
case "${COMMAND}" in
  wait-checks | failed-logs | wait-copilot) ;;
  *) usage ;;
esac
# shellcheck disable=SC2086
PR_URL=$(gh pr view ${2:-} --json url --jq .url)
IFS=/ read -r _ _ _ OWNER REPO _ NUMBER <<< "${PR_URL}"

case "${COMMAND}" in
  wait-checks)
    wait_checks
    ;;
  failed-logs)
    failed_logs
    ;;
  wait-copilot)
    wait_copilot
    ;;
esac
