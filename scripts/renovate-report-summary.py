#!/usr/bin/env python3
"""Parse Renovate report JSON and produce a structured Markdown summary.

Reads a Renovate report JSON file (the format produced by Renovate's
reportType=json option) and outputs a GitHub-flavored Markdown summary
to stdout.

Usage:
    python3 renovate-report-summary.py <path-to-renovate-report.json>
"""

import json
import sys
from collections import defaultdict


def load_report(path: str) -> dict:
    """Load the Renovate report JSON file."""
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_update_type(upgrades: list) -> str:
    """Derive combined update type from a list of upgrades."""
    types = set()
    for u in upgrades:
        ut = u.get("updateType", "")
        if ut:
            types.add(ut)
    if len(types) == 0:
        return "unknown"
    if len(types) == 1:
        return types.pop()
    return "mixed"


def format_dep_link(dep_name: str, datasource: str, package_name: str) -> str:
    """Format dependency name with link if applicable."""
    if datasource in ("github-tags", "github-releases", "git-refs"):
        # Link to the GitHub repo
        name = package_name or dep_name
        if name.startswith("https://github.com/"):
            repo_path = name.replace("https://github.com/", "")
            return f"[{dep_name}](https://github.com/{repo_path})"
        if "/" in name and not name.startswith("http"):
            return f"[{dep_name}](https://github.com/{name})"
    return dep_name


def format_version_transition(upgrade: dict) -> str:
    """Format currentValue -> newValue transition."""
    current = upgrade.get("currentValue", "")
    new_val = upgrade.get("newValue", "")
    current_digest = upgrade.get("currentDigest", "")
    new_digest = upgrade.get("newDigest", "")

    if current and new_val and current != new_val:
        return f"`{current}` -> `{new_val}`"
    if current_digest and new_digest:
        return f"`{current_digest[:12]}` -> `{new_digest[:12]}`"
    if new_val:
        return f"-> `{new_val}`"
    if new_digest:
        return f"-> `{new_digest[:12]}`"
    return ""


def result_to_status(result: str, pr_no: int | None, pr_blocked_by: str,
                     repo_name: str) -> str:
    """Convert branch result to status string with emoji."""
    status = ""
    if result == "automerged":
        status = "✅ merged"
    elif result == "error":
        status = "❌ error"
    elif result == "pending":
        status = "⏳ pending"
    elif result == "done":
        if pr_blocked_by == "BranchAutomerge":
            status = "⏳ automerge pending"
        elif pr_blocked_by == "Error":
            status = "❌ error"
        else:
            status = "✔️ done"
    elif result == "no-work":
        status = "— no work"
    elif result == "not-scheduled":
        status = "⏭️ not scheduled"
    else:
        status = f"❓ {result or 'unknown'}"

    if pr_no:
        pr_link = f"https://github.com/{repo_name}/pull/{pr_no}"
        status += f" ([PR #{pr_no}]({pr_link}))"

    return status


def generate_summary(data: dict) -> str:
    """Generate the full Markdown summary."""
    lines = []
    repositories = data.get("repositories", {})
    global_problems = data.get("problems", [])

    # -- Collect statistics --
    total_repos = len(repositories)
    repos_with_activity = 0
    total_branches_created = 0
    total_branches_updated = 0
    total_automerged = 0
    total_prs_opened = 0
    total_errors = 0
    total_pending = 0

    all_problems = []
    merged_branches = []
    active_repos = {}

    for repo_name, repo_data in repositories.items():
        branches = repo_data.get("branches", [])
        problems = repo_data.get("problems", [])
        has_activity = False

        repo_automerged = []
        repo_active_branches = []

        for branch in branches:
            result = branch.get("result")
            branch_name = branch.get("branchName", "")
            pr_no = branch.get("prNo")

            if result in ("automerged",):
                total_automerged += 1
                has_activity = True
                repo_automerged.append(branch)
                merged_branches.append((repo_name, branch_name))

            if result == "done":
                pr_blocked = branch.get("prBlockedBy", "")
                if pr_blocked == "BranchAutomerge":
                    total_pending += 1
                    has_activity = True
                elif pr_blocked == "Error":
                    total_errors += 1
                    has_activity = True
                else:
                    has_activity = True

            if result == "pending":
                total_pending += 1
                has_activity = True

            if result == "error":
                total_errors += 1
                has_activity = True

            if result and result not in ("no-work", "not-scheduled"):
                repo_active_branches.append(branch)

            if pr_no:
                total_prs_opened += 1

        if problems:
            has_activity = True
            seen_problems = set()
            for p in problems:
                key = (repo_name, p.get("branch", ""),
                       p.get("file", ""), p.get("msg", ""))
                if key in seen_problems:
                    continue
                seen_problems.add(key)
                all_problems.append({
                    "repository": repo_name,
                    "branch": p.get("branch", ""),
                    "msg": p.get("msg", ""),
                    "level": p.get("level", 30),
                    "file": p.get("file", ""),
                })

        if has_activity:
            repos_with_activity += 1
            # Deduplicate problems for per-repo display
            deduped_problems = []
            seen_repo_problems = set()
            for p in problems:
                key = (p.get("branch", ""), p.get("file", ""),
                       p.get("msg", ""))
                if key not in seen_repo_problems:
                    seen_repo_problems.add(key)
                    deduped_problems.append(p)
            active_repos[repo_name] = {
                "branches": repo_active_branches,
                "automerged": repo_automerged,
                "problems": deduped_problems,
                "package_files": repo_data.get("packageFiles", {}),
            }

    # Add global problems
    for p in global_problems:
        all_problems.append({
            "repository": p.get("repository", "global"),
            "branch": p.get("branch", ""),
            "msg": p.get("msg", ""),
            "level": p.get("level", 30),
            "file": p.get("file", ""),
        })

    # -- Section 1: Header with global statistics --
    lines.append("# Renovate Report Summary")
    lines.append("")
    lines.append("## 1. Global Statistics")
    lines.append("")
    lines.append(f"| Metric | Count |")
    lines.append(f"|--------|-------|")
    lines.append(f"| Total repositories processed | {total_repos} |")
    lines.append(
        f"| Repositories with activity | {repos_with_activity} |")
    lines.append(f"| Branches automerged | {total_automerged} |")
    lines.append(f"| PRs opened | {total_prs_opened} |")
    lines.append(f"| Pending branches | {total_pending} |")
    lines.append(f"| Errors | {total_errors} |")
    lines.append(
        f"| Warnings/Problems | {len(all_problems)} |")
    lines.append("")

    # -- Section 2: Errors and Warnings --
    if all_problems:
        lines.append("## 2. Errors and Warnings")
        lines.append("")
        lines.append("| Repository | Branch/File | Message |")
        lines.append("|------------|-------------|---------|")
        for p in all_problems:
            repo = p["repository"]
            repo_link = f"[{repo}](https://github.com/{repo})"
            branch_or_file = p["branch"] or p.get("file", "")
            msg = p["msg"].replace("|", "\\|")
            # Truncate long messages
            if len(msg) > 120:
                msg = msg[:117] + "..."
            lines.append(f"| {repo_link} | `{branch_or_file}` | {msg} |")
        lines.append("")

    # -- Section 3: Repository Details --
    lines.append("## 3. Repository Details")
    lines.append("")

    for repo_name in sorted(active_repos.keys()):
        repo_info = active_repos[repo_name]
        branches = repo_info["branches"]
        package_files = repo_info["package_files"]

        if not branches and not repo_info["problems"]:
            continue

        # H3 heading linked to GitHub
        lines.append(
            f"### [{repo_name}](https://github.com/{repo_name})")
        lines.append("")

        # Dependency managers detected
        if package_files:
            managers = sorted(package_files.keys())
            lines.append(
                f"**Dependency managers:** {', '.join(f'`{m}`' for m in managers)}")
            lines.append("")

        # Branch table
        if branches:
            lines.append(
                "| Branch | Update Type | Status | Dependencies | Files |")
            lines.append(
                "|--------|-------------|--------|--------------|-------|")

            for branch in branches:
                branch_name = branch.get("branchName", "")
                pr_no = branch.get("prNo")
                pr_blocked_by = branch.get("prBlockedBy", "")
                result = branch.get("result", "")
                upgrades = branch.get("upgrades", [])

                # Branch link
                branch_link = (
                    f"[`{branch_name}`]"
                    f"(https://github.com/{repo_name}/tree/{branch_name})"
                )

                # Update type
                update_type = get_update_type(upgrades)

                # Status
                status = result_to_status(
                    result, pr_no, pr_blocked_by, repo_name)

                # Dependencies
                deps_seen = set()
                dep_parts = []
                for u in upgrades:
                    dep_name = u.get("depName", "")
                    datasource = u.get("datasource", "")
                    package_name = u.get("packageName", "")
                    dep_key = (dep_name, u.get("newValue", ""),
                               u.get("newDigest", ""))
                    if dep_key in deps_seen:
                        continue
                    deps_seen.add(dep_key)
                    dep_link = format_dep_link(
                        dep_name, datasource, package_name)
                    version = format_version_transition(u)
                    if version:
                        dep_parts.append(f"{dep_link} {version}")
                    else:
                        dep_parts.append(dep_link)

                deps_str = "<br>".join(dep_parts) if dep_parts else "—"
                # Truncate if too many deps
                if len(dep_parts) > 5:
                    deps_str = "<br>".join(dep_parts[:5])
                    deps_str += f"<br>*... and {len(dep_parts) - 5} more*"

                # Files
                files_seen = set()
                for u in upgrades:
                    pf = u.get("packageFile", "")
                    if pf:
                        files_seen.add(pf)
                files_list = sorted(files_seen)
                if len(files_list) > 3:
                    files_str = (
                        "<br>".join(f"`{f}`" for f in files_list[:3])
                        + f"<br>*... and {len(files_list) - 3} more*"
                    )
                else:
                    files_str = (
                        "<br>".join(f"`{f}`" for f in files_list)
                        if files_list else "—"
                    )

                lines.append(
                    f"| {branch_link} | {update_type} | {status} "
                    f"| {deps_str} | {files_str} |"
                )

            lines.append("")

        # Per-repo errors
        if repo_info["problems"]:
            lines.append("**Errors:**")
            lines.append("")
            seen = set()
            for p in repo_info["problems"]:
                branch_or_file = p.get("branch", "") or p.get("file", "")
                msg = p.get("msg", "")
                key = (branch_or_file, msg)
                if key in seen:
                    continue
                seen.add(key)
                lines.append(
                    f"- `{branch_or_file}`: {msg}")
            lines.append("")

    # -- Section 4: Merged Branches summary --
    if merged_branches:
        lines.append("## 4. Merged Branches (Automerged)")
        lines.append("")
        lines.append("| Repository | Branch |")
        lines.append("|------------|--------|")
        for repo_name, branch_name in sorted(merged_branches):
            repo_link = f"[{repo_name}](https://github.com/{repo_name})"
            branch_link = (
                f"[`{branch_name}`]"
                f"(https://github.com/{repo_name}/tree/{branch_name})"
            )
            lines.append(f"| {repo_link} | ✅ {branch_link} |")
        lines.append("")
        lines.append(f"**Total automerged:** {len(merged_branches)}")
        lines.append("")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
        print(
            "Usage: python3 renovate-report-summary.py "
            "<path-to-renovate-report.json>",
            file=sys.stderr,
        )
        sys.exit(1)

    report_path = sys.argv[1]

    import os
    if not os.path.isfile(report_path):
        print(
            f"Error: file not found: {report_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    data = load_report(report_path)
    summary = generate_summary(data)
    print(summary)


if __name__ == "__main__":
    main()
