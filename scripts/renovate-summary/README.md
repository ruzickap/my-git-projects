# renovate-summary.py

Generate a clean, linkable **Markdown summary** from a
[Renovate](https://docs.renovatebot.com/) JSON report.

Renovate's machine-readable report is great for tooling but hard to read. This
script turns it into a single Markdown document that tells you, at a glance,
**what Renovate did this run** — what was merged, what is waiting, what failed,
and what needs your attention — with every repository, branch, PR, and file
linked back to GitHub.

## Features

- **Action-oriented grouping** — branches are bucketed by what Renovate
  actually did (Error, PR opened, Pending, Not scheduled, No work, Merged),
  ordered so the items needing the most attention come first.
- **Problems table** — every problem Renovate reported (deduplicated), with
  severity level, affected branch, and message.
- **Rich, linked tables** — repositories, PRs, branches, commit history, and
  changed files all link to GitHub.
- **Version + age** — each upgrade shows `old → new` plus the age of the new
  version in days (e.g. `2.11.4 → 2.11.5 (4d)`), which makes
  [`minimumReleaseAge`](https://docs.renovatebot.com/configuration-options/#minimumreleaseage)
  hold-backs obvious.
- **Totals** — aggregate counts of branches, upgrades, problems, results, and
  update types.
- **Zero dependencies** — pure Python standard library.
- **Lint-clean output** — passes
  [`markdownlint`](https://github.com/DavidAnson/markdownlint) and
  [`rumdl`](https://github.com/rvben/rumdl) (a `markdownlint-disable` directive
  for `MD013`/`MD033` is emitted for the rich tables).

## Requirements

- Python **3.9+**
- No third-party packages.

## Usage

```bash
# Read ./renovate-report.json, write Markdown to stdout
./renovate-summary.py

# Explicit report path
./renovate-summary.py path/to/renovate-report.json

# Write to a file instead of stdout
./renovate-summary.py renovate-report.json -o SUMMARY.md

# Point links at a GitHub Enterprise instance
./renovate-summary.py renovate-report.json -b https://github.example.com
```

### Options

<!-- markdownlint-disable MD013 -->

| Argument           | Description                                      | Default                |
|--------------------|--------------------------------------------------|------------------------|
| `report`           | Path to the Renovate JSON report.                | `renovate-report.json` |
| `-b`, `--base-url` | Base GitHub URL used to build links.             | `https://github.com`   |
| `-o`, `--output`   | Write the report to this file instead of stdout. | *stdout*               |
| `-h`, `--help`     | Show help and exit.                              | —                      |

<!-- markdownlint-enable MD013 -->

The script exits `0` on success and `1` if the report file is missing or is not
valid JSON.

## Generating the input report

This script consumes the JSON report that Renovate can produce in addition to
its normal run. Enable report output in your Renovate run and point the script
at the resulting file:

```bash
./renovate-summary.py renovate-report.json -o SUMMARY.md
```

Refer to the Renovate documentation for the report option appropriate to your
runner (self-hosted, GitHub Action, etc.), as the exact setting and output path
vary between setups.

## Output structure

The generated Markdown contains the following sections, in order:

1. **⚠️ Problems** — table of all reported problems.
2. **❌ Error** — updates Renovate failed to apply.
3. **✅ Pull request opened** — updates with a real PR (created, edited, or
   already existing) awaiting review/merge.
4. **🔒 Needs approval** — blocked awaiting manual approval before a PR is
   created.
5. **⏳ Pending (not created yet)** — found but no PR yet (e.g. awaiting checks,
   held by `minimumReleaseAge`, or queued for branch automerge).
6. **🚀 Merged (auto-merged, no PR)** — merged straight to the base branch via
   branch automerge.
7. **🚦 Limited (rate/limit reached)** — deferred because a Renovate limit was
   reached (PR/branch/commit/group-size).
8. **⏰ Not scheduled** — skipped, outside the schedule window.
9. **💤 No work** — nothing to do this run.
10. **❓ Unknown** — branches whose `result` did not map to any known category,
    listed so nothing is silently dropped.
11. **📊 Totals** — aggregate counts.

Each action section is preceded by a one-line description of what the category
means. Empty categories render `_None._`.

### Example

<!-- markdownlint-disable MD013 -->

````markdown
## ✅ Pull request opened (5)

Updates for which Renovate created (or updated) a real pull request -- these
await your review or merge.

| Repository      | PR / Branch  | Title         | Type  | Upgrades              |
|-----------------|--------------|---------------|-------|-----------------------|
| [owner/repo](…) | [PR #126](…) | [update X](…) | major | `12.6` → `13.0` (18d) |
````

<!-- markdownlint-enable MD013 -->

The real output additionally includes a **Files** column and uses full GitHub
URLs in every link (abbreviated as `…` above).

## How branches are classified

Renovate's report does not include explicit "created / merged / rebased" flags,
so the script derives each branch's category from the only state signals
available — `result`, `prBlockedBy`, and `prNo`. A present `prNo` always wins
(an open PR, however it got there). The category keys map to Renovate's
[`BranchResult`](https://github.com/renovatebot/renovate/blob/main/lib/workers/types.ts)
values:

<!-- markdownlint-disable MD013 -->

| Category       | Condition (`result`, unless noted)                                                                                                      |
|----------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| PR opened      | any branch with a `prNo`; or `pr-created`, `pr-edited`, `already-existed`, `rebase`                                                     |
| Needs approval | `needs-approval`, `needs-pr-approval`                                                                                                   |
| Pending        | `pending`; or `done` + `prBlockedBy: BranchAutomerge` (committed, not yet merged)                                                       |
| Merged         | `automerged`                                                                                                                            |
| Limited        | `pr-limit-reached`, `branch-limit-reached`, `commit-per-run-limit-reached`, `commit-hourly-limit-reached`, `minimum-group-size-not-met` |
| Not scheduled  | `not-scheduled`, `update-not-scheduled`                                                                                                 |
| Error          | `error`                                                                                                                                 |
| No work        | `no-work`; or `done` with no `prNo` and no automerge                                                                                    |
| Unknown        | any unrecognised `result`                                                                                                               |

<!-- markdownlint-enable MD013 -->

> **Note:** This reflects *what Renovate did in this run*, not full PR history.
> A `prNo` means a PR exists, but the report cannot tell a brand-new PR from one
> that already existed and was rebased, and it has no "new since last run"
> signal. For that you would need the GitHub API (`created_at` / `updated_at` /
> `merged_at`) or a diff of two consecutive reports.

### A note on links and `pending` branches

For `pending` updates, Renovate has not created the branch yet, so the
`branchName` in the report is only the name it *intends* to use. Links to
`/tree/<branch>`, `/blob/...`, and `/commits/<branch>` for those rows will
therefore 404 until (and unless) the branch is actually pushed. Likewise,
branches that were auto-merged and deleted will 404. A link checker run against
the output will report these — that is expected, not a bug.

## License

See the repository's license file.
