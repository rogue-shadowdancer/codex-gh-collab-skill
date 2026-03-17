# Public Release Guide

## Scope

Use this guide when the user wants to open source a repository, publish a clean public copy, or verify that a repo is safe to expose.

## Default Decision Rule

Prefer a fresh public repository with clean history when any of the following are true:

- the private source repo contains personal email addresses in commit history
- old pull requests, review threads, or internal commit history should not become public
- current file contents are clean, but old history is not

Only change an existing repository from private to public when both the current files and the retained history are acceptable to expose.

## Privacy Review Checklist

1. Scan the working tree with `scripts/git_privacy_scan.ps1 -RepoPath <repo>`.
2. Review flagged file locations before printing or sharing their contents.
3. Review git history identities and decide whether any non-public email must be removed.
4. Inspect remote URLs and ensure no credentials are embedded.
5. Confirm the repository-level docs do not contain local absolute paths or internal-only instructions.

## Clean Export Workflow

1. Copy the working tree into a fresh directory without `.git`.
2. Re-run the privacy scan in the fresh export directory.
3. Initialize a new repo with `git init -b main`.
4. Set a public-safe git identity, preferably a GitHub `users.noreply.github.com` address if the user does not want a personal email exposed.
5. Commit the clean snapshot once.
6. Create the public repo with `gh repo create OWNER/REPO --public --source . --remote origin --push`.
7. Verify visibility with `gh repo view OWNER/REPO --json visibility,isPrivate`.

## Existing Repo Visibility Change

Use `gh repo edit OWNER/REPO --visibility public --accept-visibility-change-consequences` only after the privacy checklist passes.

If the repo fails the checklist, stop and propose either:

- rewriting history with approval, or
- creating a fresh public repo from a clean export

## License Checklist

Before calling a repo open source:

1. Confirm the license identifier.
2. Add a standard `LICENSE` file.
3. Mention the license in `README.md` if the repo has root docs.
4. Commit and push the license change before announcing the repo is ready.

## Output Expectations

Report:

- whether the current tree is clean enough to publish
- whether the retained git history is safe to expose
- whether a fresh public repo is recommended
- which license was added or confirmed
- the final public repository URL when publication succeeds
