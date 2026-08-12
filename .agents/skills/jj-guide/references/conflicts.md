# Conflict Handling

Jujutsu stores conflicts in commits. A rebase, squash, or new operation can
exit successfully while leaving conflicted revisions, so command success is not
evidence of a clean result.

## Detect the relevant conflicts

```bash
jj status
jj log -r 'conflicts() & <task-revset>'
```

Use the narrow task or publication revset. Repository-wide `conflicts()` can
include unrelated work and must not be treated as owned by the current task.

## Resolve file conflicts

When the intended result is unambiguous and every affected path belongs to the
task:

1. Put the conflicted revision in an inspectable working copy.
2. Read every conflict side and surrounding code.
3. Replace the complete conflict marker with the intended content.
4. Run `jj status`, `jj diff`, and the scoped conflict query again.
5. Re-run affected tests through `$finish-nix-change`.

Jujutsu's default markers can contain a snapshot section introduced by
`+++++++` and one or more diff sections introduced by `%%%%%%%`. Do not
resolve them by mechanically choosing a side.

Do not launch `jj resolve` or an interactive merge tool in an agent session.

Stop and ask the user when the resolution changes product or host policy, mixes
unrelated changes, lacks sufficient context, or would require choosing which
operator's work to discard.

## Handle bookmark conflicts separately

A bookmark conflict represents competing targets, not file content. Inspect all
targets and their ancestry:

```bash
jj bookmark list <name> --all-remotes
jj log -r '<each-target>'
```

Never guess a correct target or use `jj bookmark set` merely to silence the
conflict. Publishing is blocked until the bookmark target is unambiguous and
the authorization in `AGENTS.md` still applies.
