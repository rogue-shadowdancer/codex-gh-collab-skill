---
name: gh-collab
description: Manage GitHub repositories and collaboration workflows with git and gh, including creating or connecting remotes, pushing branches, inspecting branch trees and history, preparing or updating pull requests, reviewing diffs, replying to review comments, and coordinating adjacent GitHub tasks. Use when Codex needs to work on a GitHub-hosted codebase, publish local work to GitHub, reason about branch state, review or respond to PRs, or handle related repository collaboration tasks.
---

# GH Collab

Use `git` for local repository state and `gh` for GitHub-hosted operations. Inspect first, confirm authentication before remote mutations, and keep destructive actions explicit.

## Quick Start

1. Confirm repo context with `git rev-parse --show-toplevel`, `git status --short --branch`, `git branch --show-current`, and `git remote -v`.
2. Confirm GitHub auth only when remote operations are required: `gh auth status`.
3. Choose the workflow: repository lifecycle, branch/history inspection, review/PR work, or adjacent collaboration.
4. Inspect before writing: branch graph, ahead/behind, changed files, target base branch, and any protected-branch policy.
5. Ask before destructive or policy-sensitive actions such as force pushes, branch deletion, merges, releases, or admin changes.

## Capability Map

### 1. Repository Lifecycle

- Initialize a local repo, connect an existing remote, or create a new GitHub repo with `gh repo create`.
- Push the first branch with upstream tracking and confirm the resulting remote state.
- Handle clone, fork, rename-remote, and default-branch discovery tasks.
- Load [references/capabilities.md](references/capabilities.md) for the full feature inventory and future extension areas.

### 2. Branch And History Workflows

- Create, switch, rename, and delete branches only after checking collaboration risk.
- Inspect tracking, ahead/behind status, merge base, divergence, and recent commit graph.
- Use [scripts/git_branch_snapshot.ps1](scripts/git_branch_snapshot.ps1) for a deterministic branch-tree snapshot.

### 3. Diff And Review Preparation

- Compare base and head refs, collect changed files, summarize diffstat, and identify the commits under review.
- Use [scripts/git_review_snapshot.ps1](scripts/git_review_snapshot.ps1) before local review or before posting GitHub comments.

### 4. Pull Requests And Review Loops

- Open, update, check out, merge, and inspect PRs with `gh pr ...`.
- Review with findings first: bugs, regressions, rollout risk, and missing tests before summaries.
- Distinguish clearly between local fixes, suggested comments, and actions that should be posted to GitHub.

### 5. Adjacent GitHub Collaboration

- Handle issues, Actions, releases, tags, forks, cherry-picks, backports, and comment triage when the task touches collaboration flow.
- Load only the relevant section from [references/command-recipes.md](references/command-recipes.md) or [references/capabilities.md](references/capabilities.md).

## Workflow Decision Points

- Need a GitHub-hosted mutation: verify `gh auth status` and confirm the target owner/repo first.
- No remote configured: inspect `git remote -v`; if absent, decide whether to create a new repo or connect an existing one.
- Protected or shared branch: avoid direct pushes unless the user explicitly wants that and repo policy permits it.
- Review scope unclear: infer the default branch from `origin/HEAD`; ask only if inference fails.
- Detached HEAD or dirty worktree: report it before starting PR, merge, or release operations.

## Standard Procedures

### Create Or Connect A Remote Repo

- Inspect `git status --short --branch`, `git remote -v`, and `git branch --show-current`.
- If creating a new GitHub repo, prefer:
  - `gh repo create <owner>/<name> --source . --remote origin --push --private`
  - Swap `--private` for `--public` or `--internal` only when the user specifies it.
- If connecting an existing remote, use:
  - `git remote add origin <url>`
  - `git push -u origin <branch>`
- After remote changes, confirm upstream tracking and default branch references.

### Publish Or Sync A Branch

- Fetch before push when remote state may have changed.
- Prefer `git push -u origin <branch>` for first publication.
- Use `--force-with-lease`, not `--force`, and only after explicit approval.
- Treat tags, submodules, Git LFS objects, and release artifacts as separate decisions.

### Inspect Branch Topology

- Run `scripts/git_branch_snapshot.ps1 -RepoPath <repo>`.
- For narrower questions, use `git branch -vv`, `git for-each-ref`, and `git log --graph --decorate --oneline --all -n <N>`.

### Review Code Or A PR

- Establish review scope first: local diff, two refs, or a GitHub PR number.
- Run `scripts/git_review_snapshot.ps1 -RepoPath <repo> -BaseRef <base> -HeadRef <head>`.
- For GitHub PRs, augment with `gh pr view`, `gh pr diff`, `gh pr checks`, and `gh pr review` only as needed.
- Default to a code-review mindset: findings first, summaries second.

### Manage Review Comments

- Read unresolved comments first.
- Separate "explain", "fix locally", and "reply on GitHub" into distinct actions.
- When addressing feedback, tie each code change to the specific risk or comment it resolves.

## Safety Rules

- Ask before `git push --force-with-lease`, branch deletion, merges, rebases on shared branches, release publication, Actions reruns that trigger deploys, or repo admin changes.
- Never use `git push --force` unless the user explicitly insists and the branch risk is clear.
- Do not assume the default branch is `main`; inspect first.
- Treat GitHub auth tokens, remote URLs, and private repo names as sensitive.
- Prefer read-only inspection when repo policy, CI status, or repo ownership is unclear.

## Bundled Resources

- [scripts/git_branch_snapshot.ps1](scripts/git_branch_snapshot.ps1): Print remotes, tracking info, branches, and a recent graph for branch-tree inspection.
- [scripts/git_review_snapshot.ps1](scripts/git_review_snapshot.ps1): Print merge base, commit list, changed files, and diffstat for review preparation.
- [references/capabilities.md](references/capabilities.md): Feature inventory organized by module, including future extension slots.
- [references/command-recipes.md](references/command-recipes.md): Concrete `git` and `gh` recipes for repo creation, branch sync, PRs, reviews, issues, Actions, and releases.

## Output Expectations

Report:

- repo path, current branch, and relevant base branch
- remotes and upstream relationship when push or PR state matters
- exact commands run for remote mutations
- review findings or blockers, with file references when applicable
- remaining manual steps, approvals, or policy risks
