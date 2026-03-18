#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
import subprocess
from typing import Sequence


def run_git(repo_path: str, args: Sequence[str]) -> list[str]:
    completed = subprocess.run(
        ["git", "-C", repo_path, *args],
        capture_output=True,
        text=True,
        errors="replace",
        check=False,
    )

    if completed.returncode != 0:
        details = "\n".join(
            part for part in (completed.stdout.strip(), completed.stderr.strip()) if part
        )
        if details:
            raise RuntimeError(f"git {' '.join(args)} failed.\n{details}")
        raise RuntimeError(f"git {' '.join(args)} failed.")

    return completed.stdout.splitlines()


def try_git(repo_path: str, args: Sequence[str]) -> list[str] | None:
    completed = subprocess.run(
        ["git", "-C", repo_path, *args],
        capture_output=True,
        text=True,
        errors="replace",
        check=False,
    )
    if completed.returncode != 0:
        return None
    return completed.stdout.splitlines()


def first_line(lines: list[str] | None) -> str:
    if not lines:
        return ""
    return lines[0].strip()


def repo_root(repo_path: str) -> str:
    return first_line(run_git(repo_path, ["rev-parse", "--show-toplevel"]))


def relative_display_path(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()
