#!/usr/bin/env python3

from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
import re

from git_script_common import relative_display_path, repo_root, run_git


PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("Windows home path", re.compile(r"C:\\Users\\")),
    ("Unix home path", re.compile(r"/(Users|home)/[^/\s]+")),
    ("GitHub token", re.compile(r"gh[pousr]_[A-Za-z0-9_]+")),
    ("Fine-grained GitHub token", re.compile(r"github_pat_[A-Za-z0-9_]+")),
    (
        "Private key header",
        re.compile(r"-----BEGIN (RSA|OPENSSH|EC|DSA|PGP)? ?PRIVATE KEY-----"),
    ),
    ("AWS access key", re.compile(r"AKIA[0-9A-Z]{16}")),
]

REMOTE_USERINFO_PATTERNS = [
    re.compile(r"https://[^@\s/]+@"),
    re.compile(r"https://[^/\s]+:[^@\s]+@"),
]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Scan the working tree, remotes, and history for publication risks."
    )
    parser.add_argument("-RepoPath", "--repo-path", dest="repo_path", default=".")
    return parser


def iter_repo_files(root: Path):
    for path in root.rglob("*"):
        ignored_dirs = {".git", "__pycache__", ".venv", "venv", "env"}
        if ignored_dirs.intersection(path.parts) or not path.is_file():
            continue
        yield path


def find_working_tree_matches(root: Path) -> dict[str, list[str]]:
    matches: dict[str, set[str]] = defaultdict(set)

    for file_path in iter_repo_files(root):
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue

        if not content:
            continue

        display_path = relative_display_path(root, file_path)
        for line_number, line in enumerate(content.splitlines(), start=1):
            for name, pattern in PATTERNS:
                if pattern.search(line):
                    matches[name].add(f"{display_path}:{line_number}")

    return {name: sorted(matches.get(name, set())) for name, _ in PATTERNS}


def main() -> int:
    args = build_parser().parse_args()
    resolved_repo_root = Path(repo_root(args.repo_path))
    working_tree_matches = find_working_tree_matches(resolved_repo_root)

    lines: list[str] = [
        f"Repo path: {resolved_repo_root}",
        "",
        "Working tree scan:",
    ]

    for name, _ in PATTERNS:
        locations = working_tree_matches.get(name, [])
        if not locations:
            lines.append(f"- {name}: none")
            continue

        lines.append(f"- {name}: {len(locations)} match(es)")
        for location in locations:
            lines.append(f"  {location}")

    lines.extend(["", "Remote URL scan:"])
    remote_lines = run_git(args.repo_path, ["remote", "-v"])
    suspicious_remotes = sorted(
        {
            line
            for line in remote_lines
            if any(pattern.search(line) for pattern in REMOTE_USERINFO_PATTERNS)
        }
    )

    if not suspicious_remotes:
        lines.append("- No remote URLs with embedded userinfo detected")
    else:
        lines.append("- Review remote URLs with embedded userinfo before publication")
        for remote_line in suspicious_remotes:
            lines.append(f"  {remote_line}")

    lines.extend(["", "Git history identities:"])
    history_emails = sorted(
        {
            line.strip()
            for line in run_git(args.repo_path, ["log", "--format=%ae"])
            if line.strip()
        }
    )
    review_emails = [
        email
        for email in history_emails
        if not email.lower().endswith("users.noreply.github.com")
    ]

    if not review_emails:
        lines.append("- No non-noreply commit emails detected in current history")
    else:
        lines.append("- Review these commit emails before public release")
        for email in review_emails:
            lines.append(f"  {email}")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
