---
name: jj-guide
description: Use Jujutsu safely in this repository. Use before editing repository files, dispatching parallel repository writers, or performing Jujutsu status, history, conflict, operation recovery, bookmark, remote, or workspace work. Do not use for explanations requiring neither edits nor version-control operations.
---

# Jujutsu Repository Guide

Treat `AGENTS.md` as the authority for repository scope and authorization. This
skill implements those policies; it never grants permission to publish, access
another machine, overwrite another change, or discard user work.

Use `$finish-nix-change` after repository edits for formatting, evaluation,
build, activation, activation recovery, and completion evidence. Keep Jujutsu
history, operation recovery, workspaces, bookmarks, and remote operations in
this skill.

## Keep the mental model straight

- The working copy `@` is already a real commit. Most `jj` commands snapshot
  file edits into it; there is no staging area.
- `jj status` shows `@`'s diff from its parent as `Working copy changes`; those
  changes already belong to `@`. Do not treat them as uncommitted or use
  `commit`, `stash`, or `new` merely to protect them.
- Prefer stable Change IDs for ownership and rewrite tracking. Commit IDs change
  when a change is rewritten.
- Bookmarks are explicit names and do not advance automatically.
- A successful command can still create conflicted changes. Inspect state after
  every mutation.

## Establish the boundary before editing

Run:

```bash
jj status
jj diff --summary
jj log -r '@ | @- | main | main@origin | next | next@origin'
jj log -r 'main..@' --reversed
```

Record the current Change ID, parent, diff scope, and intended task base. New
files are normally auto-tracked after a snapshot unless ignored; do not use Git
staging when an expected file is missing. If Jujutsu reports stale state,
divergence, concurrent operations, or unfamiliar rewrites, stop and read
[operations-and-recovery.md](references/operations-and-recovery.md).

Do not edit until the new task owns one explicit boundary:

- Continue `@` only when it already expresses the same semantic unit.
- For independent work, reuse an unclaimed empty `@` only when its parent is the
  intended base; otherwise create a change from the recorded base before editing.
- List intended semantic changes before editing. Split a general policy or
  workflow from a specialized consumer when either can land or roll back alone.
- If ownership or the base remains unclear after inspection, ask before editing.
  Do not mutate unknown work.

The agent starting a task owns this decision because it knows the new intent.
Do not rely on the previous task having prepared the next boundary. Implement a
possible correction to an earlier change in its own boundary unless `@` is
already the clear owner, then use
[fixup-folding.md](references/fixup-folding.md) after validation to decide
whether to fold, split, or retain it.

Prefer one coherent change for a simple request. Retain multiple changes only
when each boundary represents a deliberate step with its own landing or rollback
decision; explicit dependency between steps is allowed, but technical
separability alone is insufficient. Never create a final boundary merely for a
user message, validation phase, tool batch, or temporary repair.

Set or update descriptions non-interactively:

```bash
jj describe -m "<type>(<scope>): <description>"
```

Read [changes.md](references/changes.md) before any change-boundary or history
mutation.

## Make every mutation explicit and non-interactive

- Avoid interactive commands, TUIs, and editors. Supply descriptions and
  selections non-interactively.
- Use explicit Change IDs, source revsets, filesets, destinations, remotes, and
  bookmarks. Inspect a non-trivial selector before mutating it.
- Do not use Git to mutate the working copy, index, history, refs, or remotes.
- Establish ownership and scope before relying on recoverability.

After each mutation, run the smallest useful combination of:

```bash
jj status
jj log -r '@ | @-'
jj diff --summary
```

## Finish local history without publishing

Before handoff:

```bash
jj status
jj diff --summary
jj diff --git
jj show @
```

Inspect the owned task changes, descriptions, affected descendants, and scoped
conflicts. Use `$finish-nix-change` for validation and repeat affected evidence
when a history mutation changes a validated tree.

Leaving a completed change at `@` is normal. Do not run `jj commit` or
`jj new` as a ceremonial finalization step. `jj commit -m` is allowed only
when intentionally closing the current semantic boundary and immediately
starting an already identified independent change.

Completion never moves or pushes `main`.

## Load detailed guidance only when needed

- Read [revsets-and-filesets.md](references/revsets-and-filesets.md) before
  constructing non-trivial revision or path selections.
- Read [conflicts.md](references/conflicts.md) when a file or bookmark conflict
  exists or a rewrite may create one.
- Read [operations-and-recovery.md](references/operations-and-recovery.md) for
  concurrent-operation checks after a wait, undo, operation forensics,
  divergence, or stale working copies.
- Read [bookmarks-and-remotes.md](references/bookmarks-and-remotes.md) for
  fetch, temporary backups, bookmark changes, or any remote operation.
- Read [handoff-integration.md](references/handoff-integration.md) before
  consuming, adapting, publishing, or deleting one or more remote handoff
  bookmarks.
- Read [publish-main.md](references/publish-main.md) only after the user
  explicitly authorizes publishing or pushing `main`.
- Read [workspaces.md](references/workspaces.md) before dispatching parallel
  agents that may write or snapshot repository state, or before creating,
  repairing, or removing an additional workspace.

Derived from
[`mtaran/jj-guide` at `be52f89b26477cc3e97ff23e058c260332c40569`](https://github.com/mtaran/jj-guide/tree/be52f89b26477cc3e97ff23e058c260332c40569)
under the bundled MIT license. Repository-specific policy and Jujutsu 0.43
corrections intentionally replace the upstream action playbooks.
