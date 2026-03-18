#!/usr/bin/env python3

from __future__ import annotations

import argparse

from git_script_common import first_line, repo_root, run_git, try_git


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Print merge base, commit list, changed files, and diffstat."
    )
    parser.add_argument("-RepoPath", "--repo-path", dest="repo_path", default=".")
    parser.add_argument("-BaseRef", "--base-ref", dest="base_ref", default="")
    parser.add_argument("-HeadRef", "--head-ref", dest="head_ref", default="HEAD")
    parser.add_argument(
        "-MaxCommits", "--max-commits", dest="max_commits", type=int, default=20
    )
    return parser


def resolve_base_ref(repo_path: str, requested_base_ref: str) -> str:
    if requested_base_ref.strip():
        return requested_base_ref

    origin_head_ref = first_line(
        try_git(repo_path, ["symbolic-ref", "refs/remotes/origin/HEAD"])
    )
    if origin_head_ref:
        return origin_head_ref.removeprefix("refs/remotes/")

    raise RuntimeError("BaseRef was not provided and origin/HEAD could not be inferred.")


def main() -> int:
    args = build_parser().parse_args()
    repo_path = args.repo_path

    resolved_repo_root = repo_root(repo_path)
    resolved_base_ref = resolve_base_ref(repo_path, args.base_ref)
    current_branch = first_line(try_git(repo_path, ["branch", "--show-current"]))
    if not current_branch:
        current_branch = "DETACHED"

    run_git(repo_path, ["rev-parse", "--verify", resolved_base_ref])
    run_git(repo_path, ["rev-parse", "--verify", args.head_ref])

    merge_base = first_line(
        run_git(repo_path, ["merge-base", resolved_base_ref, args.head_ref])
    )
    commits = run_git(
        repo_path,
        [
            "log",
            "--oneline",
            "--decorate",
            f"{merge_base}..{args.head_ref}",
            "-n",
            str(args.max_commits),
        ],
    )
    name_status = run_git(
        repo_path,
        ["diff", "--name-status", "--find-renames", merge_base, args.head_ref],
    )
    diff_stat = run_git(
        repo_path,
        ["diff", "--stat", "--find-renames", merge_base, args.head_ref],
    )

    lines: list[str] = [
        f"Repo path: {resolved_repo_root}",
        f"Current branch: {current_branch}",
        f"Base ref: {resolved_base_ref}",
        f"Head ref: {args.head_ref}",
        f"Merge base: {merge_base}",
        "",
        "Commits in scope:",
    ]

    lines.extend(commits or ["(none)"])
    lines.extend(["", "Changed files:"])
    lines.extend(name_status or ["(none)"])
    lines.extend(["", "Diffstat:"])
    lines.extend(diff_stat or ["(none)"])

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
