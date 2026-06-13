#!/usr/bin/env python3
"""Generate a Markdown summary from a Renovate JSON report.

The report is the "json" log/report output produced by Renovate. It emits:

  1. A "Problems" table listing every problem reported (top-level and per
     repository), with severity level, affected branch, and message.
  2. One described table per action category, ordered by how much attention
     each needs (error, PR opened, pending, not scheduled, no work, merged),
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
from typing import Any

# A parsed Renovate report's repositories, as a sorted list of (name, data).
Repos = list[tuple[str, dict[str, Any]]]
# Lookup of (depName, newVersion) -> newVersionAgeInDays for one repository.
AgeIndex = dict[tuple[str, str], int]


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


# Action categories derived from a branch's (result, prBlockedBy, prNo).
# Order defines the order of tables in the "By Action" section. Each entry is
# (key, heading, description).
ACTION_CATEGORIES = [
    (
        "error",
        "❌ Error",
        "Updates Renovate failed to apply (e.g. branch update failure).",
    ),
    (
        "pr",
        "✅ Pull request opened",
        "Updates for which Renovate created (or updated) a real pull request "
        "-- these await your review or merge.",
    ),
    (
        "pending",
        "⏳ Pending (not created yet)",
        "Updates Renovate found but has not created yet, e.g. held back by "
        "`minimumReleaseAge` or pending status checks.",
    ),
    (
        "not-scheduled",
        "⏰ Not scheduled",
        "Updates skipped this run because they fell outside their configured "
        "schedule window.",
    ),
    (
        "no-work",
        "💤 No work",
        "Branches that needed no action this run (already up to date or closed).",
    ),
    (
        "merged",
        "🚀 Merged (auto-merged, no PR)",
        "Updates that passed tests and were merged straight to the base branch "
        "via branch automerge -- no pull request was opened.",
    ),
    (
        "unknown",
        "❓ Unknown",
        "Branches whose state did not map to any known category (e.g. a "
        "`done` result without a PR number, or an unrecognised `result`). "
        "Listed here so nothing is silently dropped.",
    ),
]


def classify_action(branch: dict[str, Any]) -> str:
    """Map a branch to one of the ACTION_CATEGORIES keys.

    Derived from the report's ``result``, ``prBlockedBy`` and ``prNo`` fields
    (the only state signals available). Anything that does not map cleanly --
    a ``done`` result with no ``prNo`` that is not a branch automerge, or an
    unrecognised ``result`` string -- falls back to ``unknown`` so the branch
    is still rendered (under the catch-all category) rather than dropped.
    """
    result = branch.get("result")
    if result == "done":
        blocked = branch.get("prBlockedBy")
        if branch.get("prNo") is not None:
            return "pr"
        if blocked == "BranchAutomerge":
            return "merged"
        return "unknown"
    if result in ("pending", "not-scheduled", "error", "no-work"):
        return result
    return "unknown"


def repo_url(base: str, repo: str) -> str:
    return f"{base}/{repo}"


def branch_link(base: str, repo: str, branch: dict[str, Any]) -> str:
    """Link a branch to its PR (preferred) or branch tree."""
    pr_no = branch.get("prNo")
    if pr_no is not None:
        return f"[PR #{pr_no}]({base}/{repo}/pull/{pr_no})"
    name = branch.get("branchName", "")
    return f"[`{name}`]({base}/{repo}/tree/{name})"


def title_link(base: str, repo: str, branch: dict[str, Any]) -> str:
    """Render the PR title linked to the branch's commit history."""
    title = md(branch.get("prTitle")).replace("[", "\\[").replace("]", "\\]")
    name = branch.get("branchName")
    if not name:
        return title
    return f"[{title}]({base}/{repo}/commits/{name})"


def build_age_index(repo_data: dict[str, Any]) -> AgeIndex:
    """Map (depName, newVersion) -> newVersionAgeInDays for a repo.

    The age of a target version lives in the report's full dependency
    inventory (packageFiles[].deps[].updates[]), not on the branch upgrades,
    so it must be looked up separately.
    """
    index: AgeIndex = {}
    for managers in (repo_data.get("packageFiles") or {}).values():
        for package_file in managers or []:
            for dep in package_file.get("deps") or []:
                name = dep.get("depName") or dep.get("packageName")
                if name is None:
                    continue
                for update in dep.get("updates") or []:
                    age = update.get("newVersionAgeInDays")
                    if age is None:
                        continue
                    value = update.get("newVersion") or update.get("newValue")
                    if value is not None:
                        index.setdefault((name, value), age)
    return index


def upgrade_cell(upgrade: dict[str, Any], age_index: AgeIndex) -> str:
    """Render one upgrade as a version transition, e.g. "2.11.4 → 2.11.5".

    Appends the age of the new version (e.g. "(0d)") when known. Falls back to
    digests, then to the dependency name / update type when no version
    information is available (e.g. lockFileMaintenance).
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

    # Age of the new version, looked up from the dependency inventory.
    new_value = upgrade.get("newVersion") or upgrade.get("newValue")
    age = age_index.get((name, new_value)) if name is not None and new_value else None
    age_suffix = f" ({age}d)" if age is not None else ""

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
            cells.append(f"[`{path}`]({base}/{repo}/blob/{name}/{path})")
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
        f"| {md(upgrades)} "
        f"| {files_cell(base, repo, branch)} |"
    )


def render_problems(data: dict[str, Any], repos: Repos, base: str) -> list[str]:
    """Render the "Problems" section: a table of all reported problems."""
    lines = ["## ⚠️ Problems\n"]
    rows: list[str] = []
    seen: set[tuple[str, str, str, str]] = set()
    # Top-level problems first (repository = "-"), then per-repository ones.
    sources: list[tuple[str, list[dict[str, Any]]]] = [
        ("-", data.get("problems") or [])
    ]
    sources += [(repo, r.get("problems") or []) for repo, r in repos]
    for repo, problems in sources:
        for p in problems:
            branch = p.get("branch")
            level = level_label(p.get("level"))
            key = (repo, level, branch or "", p.get("msg") or "")
            if key in seen:
                continue
            seen.add(key)
            repo_cell = f"[{md(repo)}]({repo_url(base, repo)})" if repo != "-" else "-"
            if branch and repo != "-":
                branch_cell = f"[`{branch}`]({base}/{repo}/tree/{branch})"
            elif branch:
                branch_cell = f"`{branch}`"
            else:
                branch_cell = "-"
            rows.append(
                f"| {repo_cell} | {level} | {branch_cell} | {md(p.get('msg'))} |"
            )
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


def render_totals(repos: Repos) -> list[str]:
    """Render the "Totals" section with aggregate counts."""
    all_branches = [b for _, r in repos for b in (r.get("branches") or [])]
    all_problems = [p for _, r in repos for p in (r.get("problems") or [])]
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
    repos: Repos = sorted(data.get("repositories", {}).items())
    # Per-repo lookup of new-version age, sourced from the dependency
    # inventory (packageFiles), keyed by (depName, newVersion).
    age_indexes = {repo: build_age_index(r) for repo, r in repos}

    lines: list[str] = []
    # Tables use inline <br> for multi-value cells and can exceed line-length
    # limits, so disable the rules that conflict with rich, generated tables.
    lines.append("<!-- markdownlint-disable MD013 MD033 -->")
    lines.append("# 🔄 Renovate Run Summary\n")
    lines.append(f"Repositories scanned: **{len(repos)}**\n")
    lines += render_problems(data, repos, base)
    lines += render_by_action(repos, base, age_indexes)
    lines += render_totals(repos)
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
