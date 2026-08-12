# Change Boundaries and History Mutation

Read the current tree, change descriptions, parents, descendants, and operation
baseline before rewriting history. Preserve user-created boundaries unless the
task clearly authorizes changing them.

## Contents

- Start or continue work
- Understand `jj commit`
- Split a mixed change
- Squash a correction into its owner
- Rebase only an audited set
- Treat broad rewrite commands as exceptional

## Start or continue work

Continue the current change when it already expresses the same semantic unit:

```bash
jj describe -m "<type>(<scope>): <description>"
```

For independent work, first record the exact parent tree. It may be the current
change when the new work intentionally depends on it, or an earlier change such
as `main` when it does not. Then create and describe the change explicitly:

```bash
base_change='<recorded-parent-change-id>'
jj new "$base_change"
jj describe -m "<type>(<scope>): <description>"
jj log -r '@ | @-'
```

An empty `@` is available workspace state, not proof that a new task boundary
exists. Unknown changes require investigation rather than another `jj new`.

## Understand `jj commit`

Without filesets or interactive selection, `jj commit -m MESSAGE` is
`jj describe -m MESSAGE` followed by `jj new`. The content was already a
commit at `@`; the command only records the description and creates a new
working-copy change.

Use it only when both boundaries are intentional. Do not run it merely because
validation succeeded or a response is about to be sent. Do not use
`jj commit <fileset>` as a staging model.

## Split a mixed change

Confirm that the selected and remaining portions each form a valid,
independently describable tree. Use a precise fileset and supply the selected
change's description so no editor opens:

```bash
jj split -r <change-id> <fileset> -m "<selected change description>"
jj log -r '<original-change-id> | <original-change-id>- | <original-change-id>+'
jj diff --summary -r <selected-change-id>
jj diff --summary -r <remaining-change-id>
```

The remaining revision keeps the original description; update either
description explicitly if the split changes its meaning. Do not split by path
when the same file contains inseparable intents.

## Squash a correction into its owner

When the source only repairs or completes the destination, keep the destination
description explicitly:

```bash
jj squash --from <source-change-id> --into <destination-change-id> \
  --use-destination-message
```

When the combined meaning needs a new description, use `-m` instead. A full
squash normally empties and abandons the source, then rebases descendants.
Afterward inspect:

```bash
jj log -r '<destination-change-id> | <destination-change-id>::'
jj diff --git -r <destination-change-id>
jj log -r 'conflicts() & <destination-change-id>::'
jj op log -n 3
```

Do not squash into a change whose ownership or published state is uncertain.

## Rebase only an audited set

Always specify both source selection and destination. Before running the
mutation, print the exact revset. Remember that `jj rebase -b X -o Y` selects
`(Y..X)::`, which can include descendants beyond `X`.

```bash
jj log -r '<exact-source-revset>' --reversed
jj rebase -r '<exact-source-revset>' -o <destination-change-id>
```

Use `-s` or `-b` only when their descendant behavior is intended and
audited. Inspect scoped conflicts, rewritten descendants, and the final tree.
If the tree changes, repeat the affected `$finish-nix-change` validation.

## Treat broad rewrite commands as exceptional

- `jj absorb` can rewrite several mutable ancestors. Do not use it by default;
  audit every eligible target first.
- `jj restore` discards or replaces content. Specify source, destination, and
  fileset, and use it only for owned paths with understood semantics.
- `jj abandon` reparents descendants. Inspect them before and after.
- `jj edit` makes another revision the working copy and can stale another
  workspace. Prefer a temporary child plus explicit squash when that makes the
  resolution easier to inspect.

Verify all such mutations with `jj status`, a scoped `jj log`, the relevant
`jj diff`, and `jj op log -n 3`.
