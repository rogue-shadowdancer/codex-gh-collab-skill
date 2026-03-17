# gh-collab

`gh-collab` is a Codex skill for GitHub repository work: creating or connecting remotes, publishing branches, inspecting branch topology, preparing pull requests, reviewing code, and handling adjacent GitHub collaboration tasks.

## What The Skill Covers

- Repository bootstrap and remote sync with `git` and `gh`
- Branch lifecycle, upstream tracking, and branch-tree inspection
- Diff and review preparation with deterministic local snapshots
- Pull request creation, inspection, and update workflows
- Privacy-safe open-source publication with clean-history export guidance
- License addition and public-release verification
- Review comments, issues, Actions, releases, and related GitHub tasks

## Repository Layout

- `SKILL.md`: trigger surface, workflow guidance, decision points, and safety rules
- `agents/openai.yaml`: UI-facing metadata for the skill
- `references/capabilities.md`: module inventory and future extension points
- `references/command-recipes.md`: concrete `git` and `gh` command patterns
- `references/public-release.md`: public-release checklist and privacy guidance
- `scripts/git_branch_snapshot.ps1`: branch graph and tracking snapshot
- `scripts/git_review_snapshot.ps1`: merge-base, commits, changed files, and diffstat snapshot
- `scripts/git_privacy_scan.ps1`: working-tree, remote, and history scan for publication risks

## Install

Install the skill contents into your Codex skills directory as `gh-collab`. The installed skill folder should contain the skill files only:

- `SKILL.md`
- `agents/`
- `references/`
- `scripts/`

Do not copy this repository root README into the installed skill folder.
Do not copy this repository root `README.md` or `LICENSE` into the installed skill folder.

## Validate

From the repository root:

```powershell
python "$env:CODEX_HOME\skills\.system\skill-creator\scripts\quick_validate.py" .
.\scripts\git_branch_snapshot.ps1 -RepoPath .
.\scripts\git_review_snapshot.ps1 -RepoPath . -BaseRef origin/main -HeadRef HEAD
.\scripts\git_privacy_scan.ps1 -RepoPath .
```

## Example Requests

- "Create a GitHub repo for this local project and push the current branch."
- "Show me the branch tree and explain which branch is ahead."
- "Open a PR from this branch to main and draft the title and body."
- "Review this PR and call out bugs, regressions, and missing tests."
- "Reply to the review comments and push the fixes."
- "Clean this repo for open source, create a new public repo, and add LGPL."

## Notes

- Use `git` for local repository state and `gh` for GitHub-hosted actions.
- Inspect before mutating: remotes, current branch, base branch, and auth state.
- Ask before force pushes, branch deletion, merges, releases, or repo admin changes.
- Do not make a repo public until current files and git history are reviewed for privacy.

## License

Licensed under the GNU Lesser General Public License v3.0. See `LICENSE`.
