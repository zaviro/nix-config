---
name: jj-guide
description: Use Jujutsu safely in this repository. Use before the first repository-file edit, including a newly created file intended for tracking, and for any status, diff, log, change boundary, describe/new/commit, split/squash/rebase, conflict, operation recovery, bookmark, remote, push, or workspace task. Do not use for read-only repository explanation that performs no edits or version-control operations.
---

# Jujutsu Repository Guide

Treat `AGENTS.md` as the authority for repository scope and authorization. This
skill implements those policies; it never grants permission to publish, access
another machine, overwrite another change, or discard user work.

Use `$finish-nix-change` after repository edits for formatting, evaluation,
build, activation, and completion evidence. Keep Jujutsu history and remote
operations in this skill.

This skill targets the repository's installed Jujutsu version. Run `jj version`
before relying on version-sensitive syntax and inspect `jj help <command>` if
the installed version differs from the examples.

## Keep the mental model straight

- The working copy `@` is already a real commit. Most `jj` commands snapshot
  file edits into it; there is no staging area.
- Prefer stable Change IDs for ownership and rewrite tracking. Commit IDs change
  when a change is rewritten.
- Bookmarks are explicit names and do not advance automatically.
- Every workspace has its own working-copy commit, but workspaces share changes,
  bookmarks, remotes, and the operation log.
- A successful command can still create conflicted changes. Inspect state after
  every mutation.

## Establish the boundary before editing

Run:

```bash
jj version
jj --at-op=@ --ignore-working-copy op log -n 5
```

Stop here if this read-only view reports or reveals concurrent operation heads.
Load `operations-and-recovery.md` before any command that could integrate them.
Otherwise continue:

```bash
jj status
jj diff --summary
jj log -r '@ | @- | main | main@origin'
jj log -r 'main..@' --reversed
jj --at-op=@ --ignore-working-copy op log -n 3
```

Inspect the first operation-log output before allowing `jj status` to snapshot
the working copy or integrate operation heads. Record the current
Change ID, parent, diff scope, and post-snapshot operation. New files are
normally auto-tracked after a snapshot unless ignored; do not use Git staging
when an expected file is missing.

Classify the requested work:

- **Continuation:** Continue the existing Change ID when the request repairs or
  extends that same semantic unit.
- **Independent work:** Reuse an empty, unclaimed `@`, or create a new change
  only after confirming its intended parent and dependency on the current tree.
- **Uncertain ownership or boundary:** Inspect the relevant changes and diffs.
  Do not describe, split, squash, rebase, abandon, restore, or undo unknown work.

Prefer one coherent change for a simple request. Retain multiple changes only
when each can be independently understood, validated, kept, and reverted. Never
create a final boundary merely for a user message, validation phase, tool batch,
or temporary repair.

Set or update descriptions non-interactively:

```bash
jj describe -m "<type>(<scope>): <description>"
```

Read [changes.md](references/changes.md) before using `new`, `commit`,
`split`, `squash`, `absorb`, `restore`, `abandon`, or `rebase`.

## Make every mutation explicit and non-interactive

- Never use `-i`, `--interactive`, a TUI, or a command that may open an
  editor. Supply `-m` for descriptions.
- For `split`, supply an explicit revision, fileset, and `-m`.
- When squashing two described changes, supply `-m` or
  `--use-destination-message`; a bare squash can request an editor.
- Prefer explicit Change IDs, source revsets, destinations, remotes, and
  bookmarks. Never use a broad revset merely because it probably selects only
  this task.
- Do not use Git to mutate the working copy, index, history, refs, or remotes.
- Do not rely on recoverability to justify a mutation. Establish ownership and
  scope first.

After each mutation, run the smallest useful combination of:

```bash
jj status
jj log -r '@ | @-'
jj diff --summary
jj op log -n 3
```

After a long build, activation, wait, or concurrent-agent phase, first inspect
the operation log without snapshotting or integrating heads:

```bash
jj --at-op=@ --ignore-working-copy op log -n 5
```

Compare it with the recorded baseline before continuing. If unfamiliar
operations appeared, re-establish the current change, parent, and diff before
running a normal snapshotting command.

## Finish local history without publishing

Before handoff:

```bash
jj status
jj diff --summary
jj diff --git
jj show @
```

Inspect every task change, its description, parents, descendants affected by
rewrites, and scoped conflicts. Use `$finish-nix-change` for validation. If a
history mutation changes the resulting tree or introduces conflict resolutions,
repeat the affected validation through `$finish-nix-change`.

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
  undo, operation forensics, divergence, or stale working copies.
- Read [bookmarks-and-remotes.md](references/bookmarks-and-remotes.md) for
  fetch, temporary backups, bookmark changes, or any remote operation.
- Read [publish-main.md](references/publish-main.md) only after the user
  explicitly authorizes publishing or pushing `main`.
- Read [workspaces.md](references/workspaces.md) before creating, repairing, or
  removing an additional workspace.

Derived from
[`mtaran/jj-guide` at `be52f89b26477cc3e97ff23e058c260332c40569`](https://github.com/mtaran/jj-guide/tree/be52f89b26477cc3e97ff23e058c260332c40569)
under the bundled MIT license. Repository-specific policy and Jujutsu 0.43
corrections intentionally replace the upstream action playbooks.
