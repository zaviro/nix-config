# Bookmarks and Remotes

This repository keeps exactly two long-lived remote bookmarks:

- `main` is the stable publication line. It moves forward only through the
  explicitly authorized [publish-main.md](publish-main.md) workflow.
- `next` is the mutable shared pointer to the latest selected experimental
  integration tip. An authorized update may move it forward, backward, or
  sideways and overwrite its remote target.

Ordinary task changes remain anonymous above an explicitly chosen base.
Task-specific handoff or backup bookmarks remain temporary.

## Inspect and fetch exact state

```bash
jj bookmark list main next --all-remotes
jj log -r 'main | main@origin | next | next@origin'
jj git remote list
```

Fetch only the bookmark required by the task and preserve locally reachable
work when a remote ref disappeared:

```bash
jj --config git.abandon-unreachable-commits=false \
  git fetch --remote <remote> --branch <exact-bookmark>
```

Fetch updates remote-tracking state. It does not authorize a history rewrite,
bookmark move, push, or publication.

## Move the shared `next` target

A successful `$finish-nix-change` completion authorizes synchronizing its exact
completed experimental tip to `next` unless the user requested local-only work.
Set the reviewed target, then push that exact bookmark; `next` may overwrite its
remote target:

```bash
candidate_commit='<full-validated-commit-id>'
jj bookmark set next -r "$candidate_commit" --allow-backwards
jj git push \
  --remote origin --bookmark exact:next
```

## Use temporary bookmarks only for a concrete need

For remote backup, cross-machine continuation, or agent handoff, use a
task-specific temporary name such as `agent/<task>`, or an explicitly scoped
`jj git push --change <change-id>` that creates a `push-*` bookmark.

Before creating or moving one:

1. Record its intended Change ID.
2. Confirm the name is new or owned by this task.
3. Inspect the exact outgoing range.
4. Push only that exact bookmark or change to the named remote.
5. Remove the bookmark after its stated purpose ends.

## Keep remote mutations narrow

- Never run bare `jj git push` or use `--all`.
- Push only the exact authorized bookmark to the named remote.
- Never move `main` backward or sideways; use `publish-main.md` for `main`.
- Move `next` only to the exact authorized experimental tip.
- Do not create another long-lived development bookmark.
