---
name: my-pr-review-comments
description: >-
  Triage and address review comments on a GitHub pull request: find the PR
  (current branch or given number/URL), read all unresolved review threads,
  judge whether each comment is valid, fix the valid ones, reply to and
  resolve threads, and print a summary table of fixed vs skipped comments.
  Skipped comments from AI reviewers (Copilot, Claude, CodeRabbit, Gemini,
  Codex, Cursor, other bots) get an explanatory reply and are resolved
  automatically; skipped comments from humans get a drafted reply that the
  user approves before anything is posted. Supports a dry-run mode. Use this
  whenever the user wants to address, handle, go through, fix, triage, answer,
  or resolve PR review comments, review feedback, or Copilot/bot suggestions -
  even if they just say "check the PR comments" or "deal with the review".
---

# PR Review Comments

Handle **unresolved** review comments on a GitHub pull request end-to-end:
triage, fix, reply, and resolve - while keeping the user in control of
anything said on their behalf to other humans. Resolved threads are out of
scope.

## Dry-run mode

Use dry-run when the user says "dry run", "preview", "don't post",
"just show me", or similar. In dry-run:

- Evaluate comments and make the code fixes locally, but do **not** commit,
  push, reply, or resolve anything.
- Prefix every helper call with `DRY_RUN=1` so it only prints what it would do.
- Still produce the summary table and the drafted replies, so the user can
  see exactly what a live run would post.

The reason: replies and resolved threads are visible to collaborators and
hard to undo cleanly, so previewing is cheap insurance.

## Helper script

`scripts/pr-threads.sh` (relative to this skill directory) wraps the GitHub
GraphQL calls. Use it rather than hand-writing queries - thread IDs are only
available through GraphQL and the script handles pagination.

```bash
SKILL_DIR="<path to this skill>"
"${SKILL_DIR}/scripts/pr-threads.sh" list [PR]           # unresolved threads (JSON lines)
"${SKILL_DIR}/scripts/pr-threads.sh" reply THREAD_ID "body"
"${SKILL_DIR}/scripts/pr-threads.sh" resolve THREAD_ID
```

Each `list` record contains `thread_id`, `outdated`, `path`, `line`,
`author`, `author_type`, `url`, and the full `comments` conversation.

## Workflow

### 1. Preflight

- `gh auth status` - if not logged in, stop and ask the user to run
  `gh auth login`.
- `git status --porcelain` - if there are unrelated uncommitted changes, ask
  the user how to proceed, because review fixes will be committed on top.

### 2. Find the pull request

- If the user gave a PR number or URL, use it.
- Otherwise use the current branch: `gh pr view --json number,url,title`.
- If there is no PR for the branch, run `gh pr list --author "@me"` and ask
  which one.
- Make sure you are on the PR head branch and up to date
  (`gh pr checkout <number>`, `git pull`), so fixes land in the right place.

### 3. Collect unresolved comments

Work **only on unresolved review threads**. A resolved thread has already
been handled - by the user, a previous run of this skill, or the reviewer -
so reading, re-evaluating or replying to it only creates noise.

- `scripts/pr-threads.sh list <PR>` already returns only unresolved threads
  (`isResolved == false`). Do not query resolved threads.
- If the list is empty, report "No unresolved review comments on <PR URL>"
  and stop - do not fall back to other comment sources.

Do **not** treat review summary bodies as comments to address. AI reviewers
(e.g. Copilot's "Copilot review overview" with its "Open (N)" findings list)
post a summary whose items are just links to inline threads; the summary is
never updated when those threads are resolved, so it looks open forever.
The inline threads are the source of truth. Likewise ignore empty review
bodies (they are only containers for inline replies).

Plain PR conversation comments (`gh pr view <PR> --json comments`) have no
resolved state. Consider one only if it is from a human, asks for a concrete
change, and has no later reply from the PR author - otherwise assume it is
handled. Such comments can be answered with `gh pr comment` but not resolved.

Within unresolved threads, also leave out ones where the latest reply already
settles the matter (the author answered and the reviewer agreed - suggest
resolving them instead), pure CI / coverage / changelog bot noise, and
praise-only comments.

### 4. Classify the author

The first comment of a thread defines who raised it.

- **Agent** - `author_type == "Bot"`, login ends with `[bot]`, or a known AI
  reviewer: `copilot-pull-request-reviewer`, `Copilot`, `claude`,
  `coderabbitai`, `gemini-code-assist`, `chatgpt-codex-connector`, `cursor`,
  `sourcery-ai`, `qodo-merge-pro`, `greptile-apps`.
- **Human** - everyone else. When unsure, treat as human: wrongly
  auto-resolving a person's comment is far worse than asking once too often.

### 5. Evaluate each comment

Open the file and read the surrounding code, not just the diff hunk - AI
reviewers in particular often comment on a hunk without seeing context that
makes the code correct. Decide **Fix** or **Skip**.

Fix when the comment identifies a real bug, security issue, broken behaviour,
violation of repo conventions (`AGENTS.md`, linters, style), or a clear
readability / maintainability gain.

Skip when the comment is factually wrong, already addressed, outdated (code
no longer exists), out of scope for this PR, contradicts a documented project
decision (e.g. intentional `checkov:skip`), or is a matter of taste with no
real benefit.

Judge on merit, not on effort: the user wants the PR to be better, not just
the thread count to drop. If a suggestion is partly right, fix the valid part
and say what you didn't take and why.

### 6. Apply fixes

- Make the changes and run the relevant linters / tests.
- Commit with conventional commit messages (use the `git-commit` skill if
  available); one commit per logical change.
- `git push`, then note the short SHA for each fixed comment.
- In dry-run, stop after making the local changes and show `git diff`.

### 7. Show the summary table

Print this before posting anything, so the user sees the full picture first:

```markdown
| # | Author | Type | File:Line | Comment (short) | Decision | Reason / Fix | Commit |
|---|--------|------|-----------|-----------------|----------|--------------|--------|
| 1 | copilot | Agent | src/a.ts:12 | Null check missing | Fixed | Added guard | abc1234 |
| 2 | coderabbitai | Agent | main.tf:40 | Pin provider | Skipped | Already pinned exactly | - |
| 3 | jdoe | Human | README.md:5 | Rename section | Skipped | Name used by docs links | - |
```

### 8. Reply and resolve

| Decision | Author | Action |
|----------|--------|--------|
| Fixed | Agent or Human | Reply `Fixed in <sha> - <what changed>`, then resolve |
| Skipped | Agent | Reply with a concise, factual reason, then resolve - no confirmation needed |
| Skipped | Human | Ask the user first (below) |

For the rare plain PR conversation comment selected in step 3, reply with
`gh pr comment <PR> --body "..."` quoting the original; there is nothing to
resolve. Never reply to AI review summary bodies.

#### Skipped human comments

A reply to a colleague is the user speaking, so the user decides what is
said. For each skipped human comment show:

- author, `file:line`, and the comment link
- the full original comment
- why you decided not to fix it
- a drafted reply - polite, specific, and explaining the reasoning

Then ask with the `question` tool, one question per comment:

- **Post reply and resolve** (recommended)
- **Post reply, keep thread open** - lets the reviewer respond
- **Edit the reply** - take the user's text, show it, confirm before posting
- **Fix it instead** - go back to step 6 for this comment
- **Do nothing** - leave the thread untouched

Only post or resolve what the user approved.

### 9. Final report

Repeat the table with an extra `GitHub action` column (`replied + resolved`,
`replied`, `left open`, `no action`, or `dry-run`) and the PR URL.

## Reply style

Short, factual, no filler; reference commit SHAs for fixes. Examples:

- `Fixed in abc1234 - added a null check before accessing user.email.`
- `Fixed in 014c967 - dropped issues/pull-requests read; job keeps only
  actions: read and contents: read.`
- `Not changing this - the provider version is intentionally pinned exactly
  and bumped by Renovate (see AGENTS.md).`
