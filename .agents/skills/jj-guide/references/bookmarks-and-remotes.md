# Bookmarks and Remotes

This repository keeps only `main` as a long-lived remote bookmark. Normal
local work remains anonymous above `main`; a generic feature-branch or PR
workflow is not the default.

## Inspect before changing names or remote state

```bash
jj bookmark list --all-remotes
jj log -r 'main | main@origin'
jj git remote list
```

Fetching is appropriate when a task explicitly needs synchronization, remote
freshness, backup, or publication. Fetch only the exact needed bookmark and
disable automatic abandonment so a remote deletion cannot discard locally
preserved work as a side effect:

```bash
jj --config git.abandon-unreachable-commits=false \
  git fetch --remote origin --branch <exact-bookmark>
```

Fetch updates remote-tracking state. It does not authorize rebase, bookmark
movement, push, or publication.

## Use temporary bookmarks only for a concrete need

For remote backup, cross-machine continuation, or agent handoff, use a
task-specific temporary name such as `agent/<task>`, or an explicitly scoped
`jj git push --change <change-id>` that creates a `push-*` bookmark.

Before creating or moving a temporary bookmark:

1. Record its intended Change ID.
2. Confirm the name is new or owned by this task.
3. Inspect the exact outgoing range.
4. Specify `--remote origin` and the exact bookmark or change on push.
5. Remove the temporary bookmark after its stated purpose ends.

Do not create a persistent `next` line or one bookmark per routine task or
workspace.

## Keep remote mutations narrow

- Never run bare `jj git push`.
- Never use `--all`; in 0.43 it can select every local bookmark and eligible
  tracked tag update rather than the one this task audited.
- Never assume push safety checks grant authorization or prove the range is
  correct.
- Do not force, move backward, or move sideways the published `main`.
- A PR or feature bookmark requires an explicit user request that changes the
  repository's normal direct-`main` workflow.

For an authorized `main` publication, stop here and load
[publish-main.md](publish-main.md).
