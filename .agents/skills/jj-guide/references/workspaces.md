# Additional Workspaces

Default to the current workspace. Add another only when parallel file edits,
an isolated experiment, or a long-running build materially benefits from a
separate working copy.

A fresh agent thread or context does not isolate files. Before parallel agents
write or run snapshotting Jujutsu commands, the coordinator must assign each an
explicit workspace and working directory.

Workspaces isolate files and `@`; they do not isolate the change graph,
bookmarks, remotes, or operation log. They do not require a bookmark.

## Choose an explicit base and external path

Before creation:

```bash
jj workspace list
jj status
jj log -r '@ | @- | main'
```

Choose an exact base:

- use `main` for work independent of local unpublished changes;
- use a recorded Change ID or `@` when the new work intentionally depends on
  that tree.

Without `-r`, `jj workspace add` creates the new `@` on the current
working-copy commit's parents, not on the current `@`. Never rely on that
default.

Create the destination outside the repository tree at the shared canonical
location `~/.jjworkspaces/<project-name>/<task-name>`. Use absolute paths in
commands, replacing the placeholders with concise, stable names:

```bash
jj workspace add --name <task-name> -r <base-change-id> \
  /home/<user>/.jjworkspaces/<project-name>/<task-name>
jj workspace list
```

Do not create `.worktrees/` or an `.envrc` inside this repository. New,
unignored paths can be auto-tracked by Jujutsu. Do not point `GIT_DIR` at the
main colocated repository to make third-party Git tools write through another
workspace.

## Work safely in parallel

In each workspace, establish the core `$jj-guide` baseline and record the shared
operation head without snapshotting:

```bash
jj --at-op=@ --ignore-working-copy op log -n 5
```

Give concurrent tasks non-overlapping semantic and file ownership where
practical, and wait for affected workers to stop before rewriting shared
ancestors or integrating their changes.

After history mutations, inspect all workspaces:

```bash
jj workspace list
jj log -r 'working_copies()'
jj op log -n 5
```

Rewriting another workspace's working-copy commit can make that workspace
stale. Diagnose the responsible operation before running
`jj workspace update-stale`; it can create a recovery commit if the old
operation was lost.

## Retire a workspace conservatively

Before forgetting it:

1. Run `jj status` and inspect its `<name>@` change from that workspace.
2. Confirm every wanted change is preserved in the intended stack.
3. Confirm no untracked or ignored local artifact still needs to be retained.
4. From another workspace, run `jj workspace forget <exact-name>`.
5. Verify `jj workspace list`.
6. Delete the exact canonical directory separately only after confirming it is
   outside the repository and contains no user data.

Never run `jj workspace forget` without an explicit name. Do not prescribe an
unchecked recursive deletion command.
