# Remote Handoff Integration

Use this reference with
[`$integrate-remote-handoffs`](../../integrate-remote-handoffs/SKILL.md). The
generic skill owns candidate audit, intent boundaries, interaction review, and
the validation shape. This reference supplies only this repository's Jujutsu
mechanics.

## Map each exact source

Run the core `$jj-guide` snapshot before mutation. Use
[bookmarks-and-remotes.md](bookmarks-and-remotes.md) for live lookup and exact
fetch mechanics. Record the intended local integration tip plus every source
ref, live server object, fetched remote bookmark, source Change ID, and actual
common ancestor.

A read-only audit may compare the live ref with local tracking state without
fetching. Before integration, fetch only each authorized source while preserving
locally reachable objects.

Stop if the fetched bookmark differs from the recorded live object. Inspect the
complete source range rather than only its tip:

```bash
jj log -r '<base>..<candidate>@<remote>' --reversed
jj diff --summary -r '<candidate-change-id>'
jj diff --git -r '<candidate-change-id>'
```

## Create locally owned changes

Fetched handoff changes are normally immutable, untracked remote proposals. Do
not rebase them in place or use `--ignore-immutable`. For a proposal that must
be adapted locally, duplicate each logical source change onto the recorded
local tip:

```bash
jj duplicate <source-change-id> -o <local-parent-change-id>
```

Record `source ref@object -> source Change ID -> local Change ID`. Duplicate
dependencies in order. Independent proposals may still form a linear local
stack when ancestry itself carries no useful design meaning; use a merge only
when preserving independent ancestry is intentional. Rebase or continue the
same Change ID only for an explicitly owned, mutable continuation.

Edit only the new locally owned change. Route boundary repairs through
[changes.md](changes.md) and folding through
[fixup-folding.md](fixup-folding.md). After every duplicate, edit, split,
squash, rebase, or merge, inspect the affected stack, exact diffs, descendants,
scoped conflicts, workspaces, and operation log. Keep the generic skill's
coverage record when source behavior was materially split, translated, or
omitted.

## Finish and publish the exact tree

Pass exact local Change IDs and behavior claims to `$finish-nix-change`. When
it returns a completed experimental tip, use
[bookmarks-and-remotes.md](bookmarks-and-remotes.md) to synchronize that exact
tip to `next`; do not infer the target from whichever workspace happens to be
current.

Source retirement remains separately authorized. After the target server
object is verified, delete each authorized source bookmark alone:

```bash
jj bookmark track <source>@<remote>
jj bookmark delete exact:<source>
jj git push --remote <remote> --deleted --dry-run
jj git push --remote <remote> --deleted
```

The dry run must contain exactly that deletion. Verify the live source ref is
absent before processing another. Deleting a bookmark never authorizes
abandoning its source changes or recovery history.
