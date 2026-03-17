# GH Collab Command Recipes

## Inspect Repository Context

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git remote -v
git branch -vv
gh auth status
```

Use `gh auth status` only when a GitHub-hosted operation is actually needed.

## Create A New GitHub Repository From A Local Folder

```powershell
gh repo create OWNER/REPO --source . --remote origin --push --private
```

Variations:

- Replace `--private` with `--public` or `--internal` only when the user specifies it.
- If the local branch is not the intended default branch, rename or switch before creating the repo.

## Connect An Existing Remote And Push

```powershell
git remote add origin https://github.com/OWNER/REPO.git
git push -u origin BRANCH
```

If `origin` already exists, inspect it before replacing it.

## Fetch, Rebase, And Publish

```powershell
git fetch origin
git rebase origin/main
git push origin HEAD
```

For shared history rewrites, require explicit approval and use:

```powershell
git push --force-with-lease origin HEAD
```

## Inspect Branch Topology

```powershell
scripts/git_branch_snapshot.ps1 -RepoPath .
```

Manual equivalents:

```powershell
git for-each-ref --format="%(refname:short) %(upstream:short) %(upstream:trackshort)" refs/heads
git log --graph --oneline --decorate --all -n 30
```

## Prepare A Local Review Snapshot

```powershell
scripts/git_review_snapshot.ps1 -RepoPath . -BaseRef origin/main -HeadRef HEAD
```

Useful follow-up commands:

```powershell
git diff --stat --find-renames origin/main...HEAD
git diff --name-status --find-renames origin/main...HEAD
git log --oneline --decorate origin/main..HEAD
```

## Pull Request Inspection

```powershell
gh pr view 123 --web
gh pr view 123
gh pr diff 123
gh pr checks 123
```

Use local `git diff` when remote access is unavailable or unnecessary.

## Create Or Update A Pull Request

```powershell
gh pr create --base main --head feature/my-branch --title "Title" --body-file .\pr-body.md
gh pr edit 123 --title "Updated title"
```

If the user does not provide title/body, derive them from the diff and confirm only when needed.

## Review And Comment

```powershell
gh pr review 123 --comment --body "Risk: ..."
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Blocking issue: ..."
```

Prefer drafting the review content locally before posting it.

## Issues And Follow-up Work

```powershell
gh issue list
gh issue view 456
gh issue create --title "Follow-up" --body "Context"
```

Create issues only when the user wants the work tracked remotely.

## Actions And Workflow State

```powershell
gh run list
gh run view RUN_ID --log
gh pr checks 123
```

Treat reruns or deploy-triggering workflows as explicit actions that require approval.

## Releases And Tags

```powershell
git tag
gh release list
gh release create v1.2.3 --notes-file .\release-notes.md
```

Do not publish releases as a side effect of a normal push or merge workflow.
