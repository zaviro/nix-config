# Bookmarks and Remotes

This repository keeps exactly two long-lived remote bookmarks:

- `main` is the stable publication line. It moves forward only through the
  explicitly authorized [publish-main.md](publish-main.md) workflow.
- `next` is the mutable shared pointer to the latest selected experimental
  integration tip. It may move forward, backward, or sideways only under the
  authorization and lease rules below.

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
Other `next` moves require explicit authority. Before an authorized update:

1. Fetch `next` exactly and record the fetched `next@origin` commit as the
   expected remote lease.
2. Resolve the completed Change ID again after fetch. If its tree changed,
   return to `$finish-nix-change` for affected evidence; if only commit or
   ancestry changed, repeat the ownership, range, and conflict audit.
3. Freeze the resulting full candidate commit ID. Inspect its complete ancestry
   and tree difference from the remote lease, including bookmark conflicts.

For a forward move, run:

```bash
candidate_commit='<full-validated-commit-id>'
jj bookmark move exact:next --to "$candidate_commit"
```

For an actually backward, sideways, or history-rewriting move covered by the
standing completion authority or an explicit authorization, run instead:

```bash
candidate_commit='<full-validated-commit-id>'
jj bookmark set next -r "$candidate_commit" --allow-backwards
```

Verify local `next` equals `candidate_commit`, `next@origin` still equals the
recorded lease, and neither bookmark is conflicted. Freeze the operation created
by that exact move:

```bash
publication_op="$(
  jj --ignore-working-copy op log --no-graph -n 1 -T 'id ++ "\n"'
)"
jj --at-op="$publication_op" git push \
  --remote origin --bookmark exact:next --dry-run
```

The dry run must name only `next` and the audited old and new commits.
Immediately before the real push, require the current operation to remain
`publication_op` and recheck `next` plus `next@origin` from that frozen
operation. Then push from the same operation:

```bash
jj --at-op="$publication_op" git push \
  --remote origin --bookmark exact:next
```

Jujutsu compares the server with the fetched remote-tracking state, providing
the force-with-lease safety for a rewritten `next`. If the lease changed, stop,
fetch, and repeat the audit. After success, read the live server ref and require
its object to equal `candidate_commit`; fetch `next` exactly once more and
require local `next` and `next@origin` to agree. Do not use Git to mutate refs,
bypass the safety check, or retry blindly.

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
- Move `next` onto rewritten history only through the authorized lease-safe
  workflow above.
- Do not create another long-lived development bookmark.
