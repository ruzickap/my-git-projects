#!/usr/bin/env bash
# Helper for reading, replying to and resolving GitHub PR review threads.
#
# Usage:
#   pr-threads.sh list    [PR]            # unresolved threads as JSON lines
#   pr-threads.sh reply   THREAD_ID BODY  # reply to a review thread
#   pr-threads.sh resolve THREAD_ID       # resolve a review thread
#
# PR can be a number or URL; defaults to the PR of the current branch.
# Set DRY_RUN=1 to print what reply/resolve would do without calling GitHub.

set -euo pipefail

usage() {
  sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

list_threads() {
  local PR_REF="${1:-}"
  local PR_JSON OWNER_REPO OWNER REPO PR_NUMBER
  # shellcheck disable=SC2086
  PR_JSON=$(gh pr view ${PR_REF} --json number,url)
  PR_NUMBER=$(jq -r .number <<< "${PR_JSON}")
  OWNER_REPO=$(jq -r .url <<< "${PR_JSON}" | sed -E 's#https://github.com/([^/]+/[^/]+)/pull/.*#\1#')
  OWNER=${OWNER_REPO%/*}
  REPO=${OWNER_REPO#*/}

  # shellcheck disable=SC2016
  gh api graphql --paginate \
    -F owner="${OWNER}" -F repo="${REPO}" -F pr="${PR_NUMBER}" -f query='
query($owner: String!, $repo: String!, $pr: Int!, $endCursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 50) {
            nodes {
              databaseId
              author { login __typename }
              body
              url
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved == false)
    | {
        thread_id: .id,
        outdated: .isOutdated,
        path,
        line,
        author: .comments.nodes[0].author.login,
        author_type: .comments.nodes[0].author.__typename,
        url: .comments.nodes[0].url,
        comments: [.comments.nodes[] | {author: .author.login, body}]
      }'
}

reply_thread() {
  local THREAD_ID="$1" BODY="$2"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run] reply to %s:\n%s\n' "${THREAD_ID}" "${BODY}"
    return
  fi
  # shellcheck disable=SC2016
  gh api graphql -F threadId="${THREAD_ID}" -F body="${BODY}" -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { url }
  }
}' --jq '.data.addPullRequestReviewThreadReply.comment.url'
}

resolve_thread() {
  local THREAD_ID="$1"
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run] resolve %s\n' "${THREAD_ID}"
    return
  fi
  # shellcheck disable=SC2016
  gh api graphql -F threadId="${THREAD_ID}" -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}' --jq '.data.resolveReviewThread.thread.isResolved'
}

case "${1:-}" in
  list)
    list_threads "${2:-}"
    ;;
  reply)
    [[ $# -eq 3 ]] || usage
    reply_thread "$2" "$3"
    ;;
  resolve)
    [[ $# -eq 2 ]] || usage
    resolve_thread "$2"
    ;;
  *)
    usage
    ;;
esac
