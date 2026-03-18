#!/usr/bin/env python3

from __future__ import annotations

import argparse

from git_script_common import first_line, repo_root, run_git, try_git


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Print remotes, tracking info, branches, and a recent graph."
    )
    parser.add_argument("-RepoPath", "--repo-path", dest="repo_path", default=".")
    parser.add_argument(
        "-MaxGraphCommits",
        "--max-graph-commits",
        dest="max_graph_commits",
        type=int,
        default=30,
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    repo_path = args.repo_path

    resolved_repo_root = repo_root(repo_path)
    current_branch = first_line(try_git(repo_path, ["branch", "--show-current"]))
    if not current_branch:
        current_branch = "DETACHED@" + first_line(
            run_git(repo_path, ["rev-parse", "--short", "HEAD"])
        )

    origin_head_ref = first_line(
        try_git(repo_path, ["symbolic-ref", "refs/remotes/origin/HEAD"])
    )
    default_branch = (
        origin_head_ref.removeprefix("refs/remotes/origin/")
        if origin_head_ref
        else "unknown"
    )

    status = run_git(repo_path, ["status", "--short", "--branch"])
    remotes = run_git(repo_path, ["remote", "-v"])
    branch_rows = run_git(
        repo_path,
        [
            "for-each-ref",
            "--format=%(refname:short)|%(upstream:short)|%(upstream:trackshort)|%(objectname:short)|%(subject)",
            "refs/heads",
        ],
    )
    graph = run_git(
        repo_path,
        [
            "log",
            "--graph",
            "--decorate",
            "--oneline",
            "--all",
            "-n",
            str(args.max_graph_commits),
        ],
    )

    lines: list[str] = [
        f"Repo path: {resolved_repo_root}",
        f"Current branch: {current_branch}",
        f"Default remote branch: {default_branch}",
        "",
        "Status:",
        *status,
        "",
        "Remotes:",
        *remotes,
        "",
        "Local branches:",
    ]

    for row in branch_rows:
        parts = row.split("|", 4)
        branch_name = parts[0]
        upstream = parts[1] if len(parts) >= 2 and parts[1] else "-"
        track = parts[2] if len(parts) >= 3 and parts[2] else "-"
        sha = parts[3] if len(parts) >= 4 and parts[3] else "-"
        subject = parts[4] if len(parts) >= 5 else ""
        marker = "*" if branch_name == current_branch else " "
        lines.append(
            f"{marker} {branch_name} -> {upstream} [{track}] {sha} {subject}".rstrip()
        )

    lines.extend(["", "Recent graph:", *graph])
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
