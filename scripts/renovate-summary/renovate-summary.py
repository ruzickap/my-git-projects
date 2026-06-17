#!/usr/bin/env python3
"""Generate a Markdown summary from a Renovate JSON report.

The report is the "json" log/report output produced by Renovate. It emits:

  1. A "Problems" table listing every problem reported (top-level and per
     repository), with severity level, affected branch, and message.
  2. One described table per action category, ordered by how much attention
     each needs (error, PR opened, blocked by closed PR, needs approval,
     pending, merged, limited, lock file maintenance, no work, unknown),
     grouping every branch by what Renovate did with it.
  3. A totals section.

GitHub links are derived from the repository key (assumed "owner/repo" on
github.com):

  - repo   -> https://github.com/<repo>
  - PR     -> https://github.com/<repo>/pull/<prNo>      (when prNo is set)
  - branch -> https://github.com/<repo>/tree/<branch>
  - title  -> https://github.com/<repo>/commits/<branch> (branch commit history)
  - file   -> https://github.com/<repo>/blob/<branch>/<packageFile>

Usage:
  renovate-summary.py [REPORT] [-b BASE_URL] [-o OUTPUT]

Examples:
  renovate-summary.py renovate-report.json
  renovate-summary.py report.json -b https://github.example.com -o SUMMARY.md

Run with --help for the full list of options.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from typing import Any, NamedTuple
from urllib.parse import quote

# A parsed Renovate report's repositories, as a sorted list of (name, data).
Repos = list[tuple[str, dict[str, Any]]]


class AgeIndex(NamedTuple):
    """Per-repository age lookups, sourced from the dependency inventory.

    Renovate reports an upgrade's age on different fields depending on the
    update kind, so two maps are kept:

    * ``new`` -- (depName, newVersion) -> newVersionAgeInDays, the age of the
      *target* version. Present for version bumps (major/minor/patch).
    * ``current`` -- (depName, currentVersion) -> currentVersionAgeInDays, the
      age of the *currently pinned* version. Used as a fallback for digest-only
      updates, where the report carries no age or timestamp for the new digest
      at all (only the current version's age), so it is the best stability
      signal available. It is keyed by version too (not just name) so that the
      same dependency pinned to different versions across files does not
      collapse to a single, order-dependent age.
    """

    new: dict[tuple[str, str], int]
    current: dict[tuple[str, str], int]


def tally(values: list[Any]) -> str:
    """Summarise a list as "k1: v1, k2: v2" sorted by key, or "-" if empty."""
    counts = Counter(str(v) for v in values)
    return ", ".join(f"{key}: {counts[key]}" for key in sorted(counts)) or "-"


def md(value: Any) -> str:
    """Escape characters that would break a Markdown table cell."""
    if value is None:
        return ""
    return str(value).replace("|", "\\|").replace("\n", " ")


def short(digest: str | None) -> str | None:
    """Short 7-char digest, or None."""
    return digest[:7] if digest else None


def enc_ref(ref: str) -> str:
    """Percent-encode a git ref for use in a GitHub URL path segment.

    ``/`` is preserved (GitHub's ``/tree/``, ``/commits/`` and ``/blob/``
    routes accept slash-separated refs verbatim), while spaces, ``#``, ``(``,
    ``)`` and other reserved characters are encoded so the surrounding Markdown
    link target stays valid.
    """
    return quote(ref, safe="/")


# Action categories derived from a branch's (result, prBlockedBy, prNo).
# Order defines the order of tables in the "By Action" section. Each entry is
# (key, heading, description). Keys map to Renovate's BranchResult enum
# (https://github.com/renovatebot/renovate/blob/main/lib/workers/types.ts).
ACTION_CATEGORIES = [
    (
        "error",
        "❌ Error",
        "Updates Renovate failed to apply (e.g. branch update or PR failure).",
    ),
    (
        "pr",
        "✅ Pull request opened",
        "Updates for which Renovate has a real, open pull request -- these "
        "await your review or merge.",
    ),
    (
        "blocked",
        "🚫 Blocked by closed PR",
        "Updates Renovate will not raise again because a previous PR for them "
        'was closed unmerged (Renovate\'s "PR Closed (Blocked)" state). The '
        "linked PR is closed; rename/reopen it, or tick its box on the "
        "Dependency Dashboard, to get a fresh PR.",
    ),
    (
        "needs-approval",
        "🔒 Needs approval",
        "Updates blocked awaiting manual approval (e.g. via the Dependency "
        "Dashboard or `dependencyDashboardApproval`) before a PR is created.",
    ),
    (
        "pending",
        "⏳ Pending (not created yet)",
        "Updates Renovate found but has not opened a PR for yet, e.g. awaiting "
        "status checks, held by `minimumReleaseAge`, or queued for branch "
        "automerge (committed but not merged).",
    ),
    (
        "automerged",
        "🚀 Merged (auto-merged, no PR)",
        "Updates that passed tests and were merged straight to the base branch "
        "via branch automerge -- no pull request was opened.",
    ),
    (
        "limited",
        "🚦 Limited (rate/limit reached)",
        "Updates deferred this run because a Renovate limit was reached "
        "(PR/branch/commit hourly limits, or minimum group size).",
    ),
    (
        "lock-file-maintenance",
        "🔧 Lock file maintenance",
        "Branches refreshing lock files only (`lockFileMaintenance`), with no "
        "dependency version change. Routine upkeep, typically auto-merged.",
    ),
    (
        "no-work",
        "💤 No work",
        "Branches that needed no action this run (already up to date, closed, "
        "or otherwise complete).",
    ),
    (
        "unknown",
        "❓ Unknown",
        "Branches whose `result` did not map to any known category. Listed "
        "here so nothing is silently dropped.",
    ),
]

# Renovate BranchResult values grouped by category key. Any result listed here
# is matched before the generic ``prNo`` shortcut in ``classify_action``, so a
# recognised result wins even when the branch also carries a ``prNo``. This
# matters for results that report a PR number while describing something other
# than an open PR: ``already-existed`` is Renovate's "PR Closed (Blocked)"
# state and always carries the *closed* PR's number (see
# lib/workers/repository/update/branch/index.ts), and limit/error results can
# likewise accompany an open PR. Those are filed by result rather than mistaken
# for "pr".
_RESULT_TO_CATEGORY = {
    "error": "error",
    "pr-created": "pr",
    "pr-edited": "pr",
    "already-existed": "blocked",
    "rebase": "pr",
    "needs-approval": "needs-approval",
    "needs-pr-approval": "needs-approval",
    "pending": "pending",
    "automerged": "automerged",
    "pr-limit-reached": "limited",
    "branch-limit-reached": "limited",
    "commit-per-run-limit-reached": "limited",
    "commit-hourly-limit-reached": "limited",
    "minimum-group-size-not-met": "limited",
    "no-work": "no-work",
}


def is_lock_file_maintenance(branch: dict[str, Any]) -> bool:
    """Whether a branch is a lock-file-maintenance branch.

    ``lockFileMaintenance`` is not a Renovate ``BranchResult``; it is flagged
    per upgrade. Renovate sets ``isLockFileMaintenance`` and
    ``updateType == "lockFileMaintenance"`` on each such upgrade and lifts
    ``isLockFileMaintenance`` onto the branch only when *every* upgrade is one
    (see Renovate's updates/flatten.ts and updates/generate.ts). The branch
    flag is honoured first; otherwise the branch counts as lock-file
    maintenance only when it has upgrades and *all* of them are LFM. Requiring
    all (not any) mirrors Renovate's own lifting rule and avoids misclassifying
    a branch that mixes lock-file maintenance with normal dependency updates.
    """
    if branch.get("isLockFileMaintenance"):
        return True
    upgrades = branch.get("upgrades") or []
    return bool(upgrades) and all(
        u.get("isLockFileMaintenance") or u.get("updateType") == "lockFileMaintenance"
        for u in upgrades
    )


def classify_action(branch: dict[str, Any]) -> str:
    """Map a branch to one of the ACTION_CATEGORIES keys.

    Derived from the report's ``result``, ``prBlockedBy``, ``prNo`` and
    ``isLockFileMaintenance`` fields -- the state signals Renovate exposes.

    ``result`` is consulted first: any result mapped in ``_RESULT_TO_CATEGORY``
    wins, even when the branch also carries a ``prNo``. This is because several
    results report a PR number while describing something other than an open PR
    awaiting review -- e.g. ``already-existed`` (Renovate's "PR Closed
    (Blocked)" state, carrying the *closed* PR's number) or a limit/error result
    on a branch that still has an open PR. Filing by result avoids mislabelling
    those as open PRs.

    For an unmapped result, a present ``prNo`` means a real open PR exists
    (however it got there). The ambiguous ``done`` result is then split by
    ``prBlockedBy``: ``BranchAutomerge`` means committed and queued for
    automerge (``pending``). A remaining lock-file-maintenance branch is filed
    under ``lock-file-maintenance`` (it carries no depName/version, so it would
    otherwise fall into ``no-work``/``unknown``); any other ``done`` branch is
    treated as completed work (``no-work``). Any unrecognised ``result`` falls
    back to ``unknown`` so the branch is still rendered rather than silently
    dropped.
    """
    result = branch.get("result")
    if isinstance(result, str) and result in _RESULT_TO_CATEGORY:
        return _RESULT_TO_CATEGORY[result]
    if branch.get("prNo") is not None:
        return "pr"
    if result == "done" and branch.get("prBlockedBy") == "BranchAutomerge":
        return "pending"
    if is_lock_file_maintenance(branch):
        return "lock-file-maintenance"
    if result == "done":
        return "no-work"
    return "unknown"


def repo_url(base: str, repo: str) -> str:
    return f"{base}/{repo}"


def branch_link(base: str, repo: str, branch: dict[str, Any]) -> str:
    """Link a branch to its PR (preferred) or branch tree.

    Falls back to ``-`` when neither a ``prNo`` nor a ``branchName`` is present
    so the cell never renders an empty backticked name or a dangling link.
    """
    pr_no = branch.get("prNo")
    if pr_no is not None:
        return f"[PR #{pr_no}]({base}/{repo}/pull/{pr_no})"
    name = branch.get("branchName")
    if not name:
        return "-"
    return f"[`{name}`]({base}/{repo}/tree/{enc_ref(name)})"


def title_link(base: str, repo: str, branch: dict[str, Any]) -> str:
    """Render the PR title linked to the branch's commit history.

    Falls back to ``-`` when no title is present, and to the plain title
    (unlinked) when no ``branchName`` is available, avoiding empty ``[](...)``
    links.
    """
    title = md(branch.get("prTitle")).replace("[", "\\[").replace("]", "\\]")
    if not title:
        return "-"
    name = branch.get("branchName")
    if not name:
        return title
    return f"[{title}]({base}/{repo}/commits/{enc_ref(name)})"


def build_age_index(repo_data: dict[str, Any]) -> AgeIndex:
    """Build per-repo age lookups (see ``AgeIndex``) from the inventory.

    The age of a dependency lives in the report's full inventory
    (packageFiles[].deps[]), not on the branch upgrades, so it must be looked
    up separately: ``currentVersionAgeInDays`` per dep populates the
    ``current`` map (keyed by the current version), and each update's
    ``newVersionAgeInDays`` populates the ``new`` map (keyed by the target
    version).
    """
    new_index: dict[tuple[str, str], int] = {}
    current_index: dict[tuple[str, str], int] = {}
    for managers in (repo_data.get("packageFiles") or {}).values():
        for package_file in managers or []:
            for dep in package_file.get("deps") or []:
                name = dep.get("depName") or dep.get("packageName")
                if name is None:
                    continue
                current_age = dep.get("currentVersionAgeInDays")
                current_value = dep.get("currentVersion") or dep.get("currentValue")
                if current_age is not None and current_value is not None:
                    current_index.setdefault((name, current_value), current_age)
                for update in dep.get("updates") or []:
                    age = update.get("newVersionAgeInDays")
                    if age is None:
                        continue
                    value = update.get("newVersion") or update.get("newValue")
                    if value is not None:
                        new_index.setdefault((name, value), age)
    return AgeIndex(new=new_index, current=current_index)


def age_cell(upgrade: dict[str, Any], age_index: AgeIndex) -> str:
    """Return the age suffix for an upgrade, e.g. " (4d)" or " (cur 2d)".

    Returns an empty string when no age is known. The new-version age (age of
    the *target* version) is preferred and rendered as ``(4d)``. When that is
    absent -- which is always the case for digest-only updates, since Renovate
    reports no age or timestamp for the new digest -- the age of the
    *currently pinned* version is used instead and rendered as ``(cur 2d)`` to
    signal it is the current version's age rather than the new artifact's.
    """
    name = upgrade.get("depName") or upgrade.get("packageName")
    if name is None:
        return ""
    new_value = upgrade.get("newVersion") or upgrade.get("newValue")
    new_age = age_index.new.get((name, new_value)) if new_value else None
    if new_age is not None:
        return f" ({new_age}d)"
    current_value = upgrade.get("currentVersion") or upgrade.get("currentValue")
    current_age = (
        age_index.current.get((name, current_value)) if current_value else None
    )
    if current_age is not None:
        return f" (cur {current_age}d)"
    return ""


def upgrade_cell(upgrade: dict[str, Any], age_index: AgeIndex) -> str:
    """Render one upgrade as a version transition, e.g. "2.11.4 → 2.11.5".

    Appends the age of the new version (e.g. "(0d)") when known. Falls back to
    digests, then to the dependency name / update type when no version
    information is available (e.g. lockFileMaintenance).

    Age handling has two sources, because Renovate reports it differently per
    update kind:

    * Version bumps carry ``newVersionAgeInDays`` (age of the *target*
      version), rendered as e.g. ``(4d)``.
    * Digest-only updates (container images, git submodules) carry no age or
      timestamp for the *new* digest at all. As a fallback, the age of the
      *currently pinned* version (``currentVersionAgeInDays``) is shown,
      labelled ``(cur 2d)`` to make clear it is the current version's age --
      how long the pinned tag has existed -- not the age of the new digest.
      This is the closest stability signal the report exposes for digests.
    """
    name = upgrade.get("depName") or upgrade.get("packageName")
    from_ver = (
        upgrade.get("currentVersion")
        or upgrade.get("currentValue")
        or short(upgrade.get("currentDigest"))
    )
    to_ver = (
        upgrade.get("newVersion")
        or upgrade.get("newValue")
        or short(upgrade.get("newDigest"))
    )

    age_suffix = age_cell(upgrade, age_index)

    if from_ver is not None and to_ver is not None:
        return f"`{from_ver}` → `{to_ver}`{age_suffix}"

    # No version info: fall back to dependency name or update type.
    if name is not None:
        return f"`{name}`{age_suffix}"
    update_type = upgrade.get("updateType") or "update"
    package_file = upgrade.get("packageFile")
    suffix = f" (`{package_file}`)" if package_file else ""
    return f"_{update_type}_{suffix}"


def update_types_cell(branch: dict[str, Any]) -> str:
    """Distinct update types of a branch's upgrades, e.g. "minor, patch"."""
    types = sorted(
        {u.get("updateType") or "unknown" for u in (branch.get("upgrades") or [])}
    )
    return ", ".join(types) if types else "-"


def files_cell(base: str, repo: str, branch: dict[str, Any]) -> str:
    """Distinct package files of a branch's upgrades, linked to the blob."""
    name = branch.get("branchName")
    files = sorted(
        {f for u in (branch.get("upgrades") or []) if (f := u.get("packageFile"))}
    )
    if not files:
        return "-"
    cells = []
    for path in files:
        if name:
            cells.append(
                f"[`{path}`]({base}/{repo}/blob/{enc_ref(name)}/{enc_ref(path)})"
            )
        else:
            cells.append(f"`{path}`")
    return "<br>".join(cells)


# Bunyan log levels used by Renovate in its problem records.
_LEVELS = {10: "trace", 20: "debug", 30: "info", 40: "warn", 50: "error", 60: "fatal"}


def level_label(level: Any) -> str:
    """Human-readable name for a numeric bunyan log level."""
    if level is None:
        return "-"
    return _LEVELS.get(level, str(level))


def branch_row(
    base: str,
    repo: str,
    branch: dict[str, Any],
    age_index: AgeIndex,
) -> str:
    """Render one branch as a Markdown table row.

    A leading linked Repository cell is included; the result is omitted because
    it is implied by the section heading the row appears under.
    """
    upgrades = "<br>".join(
        upgrade_cell(u, age_index) for u in (branch.get("upgrades") or [])
    )
    return (
        f"| [{md(repo)}]({repo_url(base, repo)}) "
        f"| {branch_link(base, repo, branch)} "
        f"| {title_link(base, repo, branch)} "
        f"| {update_types_cell(branch)} "
        f"| {md(upgrades) or '-'} "
        f"| {files_cell(base, repo, branch)} |"
    )


def collect_problems(
    data: dict[str, Any], repos: Repos
) -> list[tuple[str, dict[str, Any]]]:
    """Deduplicated list of (repo, problem) pairs across the whole report.

    Combines the top-level ``data['problems']`` (repository ``"-"``) with each
    repository's ``problems``, deduplicating on (repo, level, branch, msg) so
    the Problems table and the totals count always agree.
    """
    seen: set[tuple[str, str, str, str]] = set()
    collected: list[tuple[str, dict[str, Any]]] = []
    sources: list[tuple[str, list[dict[str, Any]]]] = [
        ("-", data.get("problems") or [])
    ]
    sources += [(repo, r.get("problems") or []) for repo, r in repos]
    for repo, problems in sources:
        for p in problems:
            key = (
                repo,
                level_label(p.get("level")),
                p.get("branch") or "",
                p.get("msg") or "",
            )
            if key in seen:
                continue
            seen.add(key)
            collected.append((repo, p))
    return collected


def render_problems(data: dict[str, Any], repos: Repos, base: str) -> list[str]:
    """Render the "Problems" section: a table of all reported problems."""
    lines = ["## ⚠️ Problems\n"]
    rows: list[str] = []
    for repo, p in collect_problems(data, repos):
        branch = p.get("branch")
        level = level_label(p.get("level"))
        repo_cell = f"[{md(repo)}]({repo_url(base, repo)})" if repo != "-" else "-"
        if branch and repo != "-":
            branch_cell = f"[`{branch}`]({base}/{repo}/tree/{enc_ref(branch)})"
        elif branch:
            branch_cell = f"`{branch}`"
        else:
            branch_cell = "-"
        rows.append(f"| {repo_cell} | {level} | {branch_cell} | {md(p.get('msg'))} |")
    if rows:
        lines.append("| Repository | Level | Branch | Message |")
        lines.append("| --- | --- | --- | --- |")
        lines.extend(rows)
        lines.append("")
    else:
        lines.append("_No problems._\n")
    return lines


def render_by_action(
    repos: Repos, base: str, age_indexes: dict[str, AgeIndex]
) -> list[str]:
    """Render one table per action category, ordered by attention needed."""
    lines: list[str] = []
    by_action: dict[str, list[tuple[str, dict[str, Any]]]] = {}
    for repo, r in repos:
        for branch in r.get("branches") or []:
            by_action.setdefault(classify_action(branch), []).append((repo, branch))
    for key, heading, description in ACTION_CATEGORIES:
        branches = by_action.get(key, [])
        lines.append(f"## {heading} ({len(branches)})\n")
        lines.append(f"{description}\n")
        if not branches:
            lines.append("_None._\n")
            continue
        lines.append("| Repository | PR / Branch | Title | Type | Upgrades | Files |")
        lines.append("| --- | --- | --- | --- | --- | --- |")
        for repo, branch in branches:
            lines.append(branch_row(base, repo, branch, age_indexes[repo]))
        lines.append("")
    return lines


def render_totals(data: dict[str, Any], repos: Repos) -> list[str]:
    """Render the "Totals" section with aggregate counts."""
    all_branches = [b for _, r in repos for b in (r.get("branches") or [])]
    all_problems = collect_problems(data, repos)
    all_upgrades = [u for b in all_branches for u in (b.get("upgrades") or [])]
    results = tally([b.get("result") or "unknown" for b in all_branches])
    types = tally([u.get("updateType") or "unknown" for u in all_upgrades])
    return [
        "## 📊 Totals\n",
        f"- **Branches/PRs:** {len(all_branches)}",
        f"- **Upgrades:** {len(all_upgrades)}",
        f"- **Problems:** {len(all_problems)}",
        f"- **Results:** {results}",
        f"- **Update types:** {types}",
    ]


def build_report(data: dict[str, Any], base: str) -> str:
    """Build the full Markdown report from a parsed Renovate JSON report."""
    repos: Repos = sorted((data.get("repositories") or {}).items())
    # Per-repo age lookups, sourced from the dependency inventory
    # (packageFiles): new-version age keyed by (depName, newVersion), plus
    # current-version age keyed by depName for digest-update fallbacks.
    age_indexes = {repo: build_age_index(r) for repo, r in repos}

    lines: list[str] = []
    # Tables use inline <br> for multi-value cells and can exceed line-length
    # limits, so disable the rules that conflict with rich, generated tables.
    lines.append("<!-- markdownlint-disable MD013 MD033 -->")
    lines.append("# 🔄 Renovate Run Summary\n")
    lines.append(f"Repositories scanned: **{len(repos)}**\n")
    lines += render_problems(data, repos, base)
    lines += render_by_action(repos, base, age_indexes)
    lines += render_totals(data, repos)
    return "\n".join(lines) + "\n"


DEFAULT_REPORT = "renovate-report.json"
DEFAULT_BASE_URL = "https://github.com"


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate a Markdown summary from a Renovate JSON report.",
    )
    parser.add_argument(
        "report",
        nargs="?",
        default=DEFAULT_REPORT,
        help=f"path to the Renovate JSON report (default: {DEFAULT_REPORT})",
    )
    parser.add_argument(
        "-b",
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"base GitHub URL for links (default: {DEFAULT_BASE_URL})",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="write the report to this file instead of stdout",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """CLI entry point. Returns a process exit code."""
    args = parse_args(argv)

    try:
        with open(args.report, encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        print(f"Error: report file '{args.report}' not found.", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"Error: '{args.report}' is not valid JSON: {exc}", file=sys.stderr)
        return 1

    report = build_report(data, args.base_url.rstrip("/"))

    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(report)
    else:
        sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
