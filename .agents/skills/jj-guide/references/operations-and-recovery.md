# Operation Forensics and Recovery

The operation log is shared by all workspaces and records repository views,
including bookmarks and each workspace's `@`. Treat it as forensic evidence,
not as permission to rewind broadly.

After a long build, wait, or concurrent-agent phase, inspect the operation log
without snapshotting before resuming normal Jujutsu commands:

```bash
jj --at-op=@ --ignore-working-copy op log -n 5
```

If unfamiliar operations appeared, re-establish the current change, parent,
working copies, and diff before continuing.

## Re-establish a baseline

```bash
jj --at-op=@ --ignore-working-copy op log -n 10
jj --at-op=@ --ignore-working-copy status
jj --at-op=@ --ignore-working-copy log -r 'working_copies() | main | main@origin'
```

Compare operation IDs, username, hostname, workspace, description, and time with
the last operation known to the task when available. Using `--at-op=@` with
`--ignore-working-copy` prevents this first look from snapshotting files or
reconciling divergent heads. With or without a prior baseline, an unfamiliar
operation requires re-inspection of the current change, parent, and diff before
any further mutation.

## Inspect without restoring

Use old operations read-only:

```bash
jj --at-op=@ --ignore-working-copy op show <operation-id>
jj --at-op=@ --ignore-working-copy op diff \
  --from <older-operation-id> --to <newer-operation-id>
jj --at-op=<operation-id> status
jj --at-op=<operation-id> log
jj --at-op=<operation-id> diff -r <change-id>
```

`--at-op` disables working-copy snapshotting, but mutation commands are still
possible. Use it only with read-only inspection commands.

## Choose the narrowest recovery

- Use `jj undo` only when the current latest operation is confirmed to be the
  exact operation this task must reverse and no other operator owns it.
- `jj op revert <operation-id>` can invert a specific non-latest operation,
  but its effects can conflict with later work. Inspect the operation and
  request confirmation before using it in shared or uncertain history.
- `jj op restore <operation-id>` restores the entire repository view,
  including bookmarks and workspace commits. Use it only with explicit user
  confirmation after showing what later operations would be displaced.
- Recover individual file content by inspecting the old operation and applying
  the smallest owned change forward; do not restore the whole repository merely
  to retrieve one file.

After recovery, run `jj status`, a scoped log and diff, the conflict query, and
`jj --at-op=@ --ignore-working-copy op log -n 3`.

## Handle divergence and stale workspaces

Lock-free concurrent operations can produce divergent Change IDs or operation
heads. Do not automatically abandon one side. Inspect:

```bash
jj --at-op=@ --ignore-working-copy log -r 'divergent()'
jj --at-op=@ --ignore-working-copy evolog -r <change-id>
jj --at-op=@ --ignore-working-copy op log
```

Resolve only when ownership and intended content are clear.

Before `jj workspace update-stale`, identify which workspace or rewrite made
the working copy stale. If the workspace's recorded operation was lost,
`update-stale` may create a recovery commit containing its files. Inspect and
preserve that commit rather than treating it as disposable.

Remote pushes are not undone by local operation recovery. Repair published
`main` with a new forward fix or revert change and a separately authorized
publication. Never move published `main` backward.
