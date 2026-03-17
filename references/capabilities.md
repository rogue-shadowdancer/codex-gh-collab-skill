# GH Collab Capability Inventory

## Core Modules

### 1. Repository bootstrap and remote sync

- Initialize a local repository.
- Add, rename, inspect, or replace remotes.
- Create a GitHub repository from a local folder with `gh repo create`.
- Push the initial branch and set upstream tracking.
- Clone or fork a repository when the user wants a fresh local copy.
- Confirm visibility, owner, default branch, and auth state before remote writes.

### 2. Branch lifecycle and branch-tree inspection

- Create, switch, rename, and delete branches.
- Inspect local and remote tracking with `git branch -vv` and `git for-each-ref`.
- Show a graph of branch relationships and recent commit history.
- Compare branch divergence, ahead/behind state, and merge base.
- Clean up stale local branches only after confirming they are safe to remove.

### 3. Commits, diffs, and local review prep

- Inspect status, staged changes, unstaged changes, and untracked files.
- Review changed files, rename detection, diffstat, and commit ranges.
- Compare two refs or prepare a review snapshot from base to head.
- Summarize behavioral risk, regression risk, and missing tests.

### 4. Pull request lifecycle

- Create a PR, set title and body, and choose base and head branches.
- Update PR metadata or push follow-up commits.
- Check out a PR locally for inspection.
- Inspect checks, reviewers, labels, and mergeability.
- Merge with merge, squash, or rebase only when the user asks and policy allows it.

### 5. Review and discussion handling

- Read PR comments and review threads.
- Draft review findings with file and line references.
- Distinguish between comments to post remotely and local implementation work.
- Reply to comments after fixes land.
- Re-review after changes and note which issues are resolved versus still open.

### 6. Collaboration around issues and planning

- List or inspect issues.
- Create issues from discovered follow-up work.
- Link PRs to issues with closing keywords when appropriate.
- Inspect labels, assignees, milestones, or project linkage when the workflow depends on them.

## Adjacent Modules

### 7. Actions and CI state

- Inspect workflow runs and job results.
- Check whether required checks are green before merge.
- Re-run failed workflows only with user approval when reruns have side effects.
- Pull logs for failing jobs when debugging is required.

### 8. Releases, tags, and distribution

- Inspect or create tags.
- Draft or publish releases.
- Confirm changelog source and release target branch.
- Keep release publication as an explicit action, not a default side effect.

### 9. Forks, upstreams, and backports

- Add upstream remotes for fork-based work.
- Sync a fork with upstream.
- Cherry-pick fixes into maintenance branches.
- Prepare backport branches and follow-up PRs.

### 10. Repo policy and administration

- Inspect branch protection symptoms when pushes or merges fail.
- Reason about required reviews, status checks, and permissions.
- Coordinate repo settings changes only when the user explicitly requests admin work.

## Extension Pattern

Add future features without rewriting the whole skill:

1. Add a new module to this file under either Core Modules or Adjacent Modules.
2. Add the smallest needed command recipes to `references/command-recipes.md`.
3. Add a script under `scripts/` only when the workflow is repetitive or fragile enough to justify automation.
4. Link the new module from `SKILL.md` only if it changes the default workflow or trigger surface.

## Candidate Future Expansions

- GitHub Discussions triage
- Codeowners and review routing
- Security alerts and Dependabot workflows
- Projects and milestone reporting
- Multi-repo coordination and bulk branch audits
- Repo migration between owners or organizations
