---
name: my-pr-autopilot
description: >-
  Drive a freshly opened GitHub pull request to "ready to merge": wait for CI,
  fix failing checks and push until everything is green, mark the PR ready for
  review, get a Copilot review, address its comments with my-pr-review-comments,
  make CI green again, and finish with a short itemized summary. Use right
  after a PR is created, or whenever the user says things like "babysit this
  PR", "get the PR green", "watch CI and fix it", "make the PR ready", "PR
  autopilot" - even if they only mention part of the loop (e.g. "wait for the
  checks and then let Copilot review it").
license: Apache-2.0
---

# PR Autopilot

Take the user's own pull request from "just opened" to "green, reviewed, and
ready to merge" with as little babysitting as possible:

1. Make CI green (fix, push, wait - repeat).
2. Mark the PR ready for review.
3. Get one Copilot review and address it with `my-pr-review-comments`.
4. Make CI green again.
5. Report a short itemized summary.

The user is expected to walk away while this runs, so work autonomously where
it is safe (CI fixes on the PR branch) and ask only where a human decision is
really needed (review replies, anything destructive).

## Ground rules

- **Honest green.** Fix the root cause. Do not disable or skip checks, delete
  or weaken tests, loosen linter configs, or add suppressions just to turn a
  check green - a green that hides a problem is worse than a red one. If a
  suppression really is the right fix (a verified false positive), keep it
  narrow, explain it in a code comment, and call it out in the summary.
- **Allowed without asking:** commit and push normal (fast-forward) commits to
  the PR head branch to fix CI, and re-run failed jobs.
- **Also allowed without asking:** rebase onto the base branch to resolve
  merge conflicts, then `git push --force-with-lease` (see Preflight).
- **Ask first:** any other force-push or history rewrite, change
  workflow files to skip/disable jobs, touch repository settings or secrets,
  close or merge the PR. Never merge the PR - that stays the user's call.
- Follow the repo's `AGENTS.md`, linters, and conventional commits (use the
  `git-commit` skill if available). One commit per logical fix.
- Keep a running log of what failed, what you changed, and every pushed
  commit SHA - the final summary is built from it.

## Helper script

`scripts/pr-autopilot.sh` (relative to this skill directory) does the
waiting and log fetching, so you don't hand-write polling loops:

```bash
SKILL_DIR="<path to this skill>"
"${SKILL_DIR}/scripts/pr-autopilot.sh" wait-checks [PR]  # wait for CI
"${SKILL_DIR}/scripts/pr-autopilot.sh" failed-logs [PR]  # failing job logs
"${SKILL_DIR}/scripts/pr-autopilot.sh" wait-copilot [PR] # wait for Copilot
```

- `wait-checks` prints every check (`bucket`, workflow, name, link) and a
  `RESULT:` line. Exit: `0` passed, `1` failed or cancelled, `2` timeout
  (60 min), `3` no checks at all.
- `failed-logs` prints, for every failing GitHub Actions job, the lines with
  error markers (with line numbers), the last lines before post-job cleanup,
  and the path of the saved full log - grep that file when the excerpt is not
  enough. Non-Actions checks are reported as external.
- `wait-copilot` exits `0` when Copilot has reviewed (prints the review
  body), `2` on timeout (20 min), `3` if Copilot was never requested
  (within 2 min).

The waits are long. Run them with a tool timeout longer than the script's own
timeout (e.g. 65 minutes for `wait-checks`) or as a background command and
wait for the completion notification. A default 2-minute tool timeout would
kill the wait halfway.

## Workflow

### 1. Preflight

- `gh auth status` - if not logged in, stop and ask the user to run
  `gh auth login`.
- Find the PR: use the number/URL the user gave, otherwise the current branch
  (`gh pr view --json number,url,title,state,isDraft,headRefName,mergeable`).
  If there is none, list `gh pr list --author "@me"` and ask. If it is merged
  or closed, stop.
- Be on the PR head branch and up to date (`gh pr checkout <n>`, `git pull`).
- `git status --porcelain` - if there are unrelated uncommitted changes, ask
  how to proceed, because fixes will be committed on top.
- If `mergeable` is `CONFLICTING`, CI usually does not run. Resolve the
  conflicts without asking: `git fetch origin <base>`,
  `git rebase origin/<base>`, fix each conflict keeping the intent of both
  sides, verify locally (linters/tests for touched files), then
  `git push --force-with-lease`. Note it in the summary. Ask only if a
  conflict's correct resolution is genuinely ambiguous.

### 2. Get CI green

Loop:

1. Make sure GitHub is testing what you think it is: local `HEAD` must equal
   the PR's `headRefOid` (push first if it doesn't).
2. Run `wait-checks`.
   - `0` - green, go to step 3.
   - `3` - the repo runs no checks for this PR; note it and go to step 3.
   - `2` - something is stuck; show the pending checks and ask: keep waiting,
     continue anyway, or stop.
   - `1` - run `failed-logs` and diagnose each failure (below).
3. Fix everything that failed **in one push** where possible - every push
   restarts all workflows, so batching saves a full CI cycle.
4. Reproduce and verify locally before pushing whenever it is cheap: the same
   linter, test, or `prek run --files <changed files>`. Commit, push,
   and go back to 1.

Diagnose before fixing - the right reaction depends on the cause:

- **Caused by the PR's changes** (lint, tests, build, docs) - fix it,
  commit, push.
- **Flaky or infrastructure** (network timeout, HTTP 429, lost runner,
  cancelled by a newer run) - `gh run rerun <run_id> --failed` once, no code
  change.
- **Already failing on the base branch** (check
  `gh run list --branch <base> --workflow <workflow> --limit 3`) - not this
  PR's fault; ask: fix it here anyway, ignore this check, or stop.
- **Needs secrets, permissions, or settings** you can't change - ask.
- **External (non-Actions) check** - report the link and ask.
- **Bad commit message** (e.g. `commit-check`) - needs a history rewrite and
  force-push, so ask first.

**Stop and ask** when the same check still fails after 3 fix attempts, or
after 6 fix pushes in this phase. A loop that doesn't converge usually means
a wrong diagnosis or missing access, and more pushes only add noise. Offer:
keep trying (with your new theory), skip this check, or stop.

### 3. Mark ready for review

If the PR is a draft, run `gh pr ready <PR>`; otherwise note it was already
ready. Marking ready can start extra workflows (`ready_for_review` event) and
usually triggers Copilot automatically - both are handled below.

### 4. Copilot review (one round)

Run `wait-copilot`:

- `0` - Copilot reviewed. If the review body says Copilot could not review
  the PR (an error), tell the user and ask whether to re-request it once
  (`gh pr edit <PR> --add-reviewer @copilot`) or skip.
- `3` - Copilot was not requested automatically. Request it without asking:
  `gh pr edit <PR> --add-reviewer @copilot`, then run `wait-copilot` again.
  If the request fails (e.g. Copilot review not available for the repo), note
  it and go to step 5.
- `2` - timed out; ask: keep waiting or skip.

Then handle the comments:

- Load the `my-pr-review-comments` skill and follow it for this PR **as
  written, including all its confirmations** - the summary table, the single
  batch "Proceed?" question, and the per-comment questions for human
  reviewers. The user wants to stay in control of what gets posted on the PR,
  so don't shortcut them.
- If it finds no unresolved threads (e.g. Copilot reported "No open
  issues"), just note that.
- Do **not** re-request Copilot after the fixes - one review round is the
  agreed scope. Only do another round if the user explicitly asks.

### 5. Get CI green again

Repeat step 2 - the review fixes and the ready-for-review event both start
new runs. Run `wait-checks` even if nothing was pushed in step 4, so the
summary reflects the final state. If the user cancelled the push inside
`my-pr-review-comments`, mention the unpushed local commits.

### 6. Final summary

End with a short, itemized summary a non-expert can skim in 20 seconds.
Plain language, one bullet per phase, every pushed commit SHA listed, and be
upfront about anything that is not green or still needs the user:

```markdown
## PR autopilot: <PR title> (#<number>)

<PR URL>

- **CI (first run):** 2 checks failed -> fixed a shellcheck warning in
  `scripts/run.sh` (`abc1234`); re-ran the flaky link checker
- **Ready for review:** marked ready (was a draft)
- **Copilot review:** 4 comments -> 3 fixed (`def5678`, `0a1b2c3`),
  1 skipped (false positive: variable is always set); all threads resolved
- **CI (final):** all 14 checks green
- **Needs your attention:** nothing - ready to merge
```

If you stopped early (cap reached, user said stop, timeout), still print the
summary and say where it stopped and what is left to do.
