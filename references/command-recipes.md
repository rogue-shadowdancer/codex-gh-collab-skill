# GH Collab Command Recipes

When using the bundled helper scripts, prefer `python3 scripts/*.py` on macOS/Linux and `.\scripts\*.ps1` in Windows PowerShell.

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

```bash
python3 scripts/git_branch_snapshot.py --repo-path .
# Windows PowerShell: .\scripts\git_branch_snapshot.ps1 -RepoPath .
```

Manual equivalents:

```powershell
git for-each-ref --format="%(refname:short) %(upstream:short) %(upstream:trackshort)" refs/heads
git log --graph --oneline --decorate --all -n 30
```

## Prepare A Local Review Snapshot

```bash
python3 scripts/git_review_snapshot.py --repo-path . --base-ref origin/main --head-ref HEAD
# Windows PowerShell: .\scripts\git_review_snapshot.ps1 -RepoPath . -BaseRef origin/main -HeadRef HEAD
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
gh pr create --base main --head feature/my-branch --title "Title" --body-file ./pr-body.md
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

## Scan A Repo Before Public Release

```bash
python3 scripts/git_privacy_scan.py --repo-path .
# Windows PowerShell: .\scripts\git_privacy_scan.ps1 -RepoPath .
git log --format='%h %ae' main
```

Interpretation:

- Any token, key header, or local path finding blocks publication until removed.
- Any commit email that is not a GitHub `users.noreply.github.com` address should be reviewed before public release.
- If the repo contains private history you do not want exposed, export a clean public repo instead of changing visibility in place.

## Export A Clean Public Repository

From a new export directory that does not contain the original `.git` history:

```powershell
git init -b main
git config user.name "PUBLIC_NAME"
git config user.email "12345678+user@users.noreply.github.com"
git add .
git commit -m "Initial public release"
gh repo create OWNER/REPO --public --source . --remote origin --push
```

Use this flow when the private source repo contains old emails, internal reviews, or commits that should not become public.

## Change Existing Repository Visibility

Only do this after a clean privacy review:

```powershell
gh repo edit OWNER/REPO --visibility public --accept-visibility-change-consequences
```

If the repo fails the privacy review, stop and either rewrite history with approval or create a fresh public repo instead.

## Add Or Update A License

Inspect available license identifiers:

```powershell
gh repo license list
```

Fetch canonical license text and write it to `LICENSE`:

```powershell
gh repo license view lgpl-3.0 > LICENSE
git add LICENSE
git commit -m "Add LGPL-3.0 license"
git push origin main
```

If the repository has a root `README.md`, add a short license note there as well.

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
gh release create v1.2.3 --notes-file ./release-notes.md
```

Do not publish releases as a side effect of a normal push or merge workflow.
