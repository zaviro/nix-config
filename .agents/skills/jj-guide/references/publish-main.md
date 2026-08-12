# Publish Main

Load this playbook only after the user explicitly requests publication or
pushes `main`. Ordinary editing, completion, delivery, validation, activation,
or a request to “commit” does not authorize it.

Require `$finish-nix-change` to have completed all applicable validation and
activation first.

Keep the recorded values below in one shell session. Execute every fenced block
as one command and proceed only when the whole block exits successfully. The
`&&` chains are publication gates, not cosmetic shell style. If the execution
tool starts a new shell, re-establish and re-audit every recorded value.

## 1. Fetch and verify remote state

```bash
jj --config git.abandon-unreachable-commits=false \
  git fetch --remote origin --branch main &&
jj bookmark list main --all-remotes &&
local_conflicts="$(jj bookmark list main --conflicted)" &&
remote_conflicts="$(
  jj bookmark list main --remote origin --conflicted
)" &&
test -z "$local_conflicts" &&
test -z "$remote_conflicts" &&
jj log -r 'exactly(main, 1)' &&
jj log -r 'exactly(main@origin, 1)'
```

Stop on fetch failure, missing or conflicted bookmarks, or uncertain remote
state. Do not guess, overwrite, or switch to another remote. Inspect the fetch
operation and candidate evolution: a same-Change-ID remote rewrite can rebase
local descendants even with automatic abandonment disabled. If the candidate
was rewritten or its tree changed, repeat affected validation before proceeding.

Record the exact fetched remote target for the later concurrency check:

```bash
remote_main_commit="$(
  jj log --no-graph -r 'exactly(main@origin, 1)' \
    -T 'commit_id ++ "\n"'
)" &&
test -n "$remote_main_commit"
```

## 2. Locate and inspect the candidate

Locate the task stack's intended tip by stable Change ID:

```bash
candidate_change='<task-change-id>'
jj log -r "exactly($candidate_change, 1)" &&
jj log -r "main@origin..$candidate_change" --reversed &&
jj diff --from main@origin --to "$candidate_change" &&
task_conflicts="$(
  jj log --no-graph \
    -r "conflicts() & (main@origin..$candidate_change)" \
    -T 'commit_id ++ "\n"'
)" &&
test -z "$task_conflicts"
```

Require:

- every revision in the range belongs to this publication;
- descriptions and parentage are accurate;
- no file or bookmark conflict remains;
- no unpublished prerequisite or unrelated task is being included.

Stop if any condition fails.

## 3. Establish the fetched remote as the exact base

If the candidate is not yet a descendant of fetched `main@origin`, determine
whether it is valid work based on an older `main`. Stop on unrelated ancestry or
uncertainty. For a valid stale base, inspect the complete rewrite set before
rebasing. In Jujutsu 0.43, `rebase -b X -o Y` rewrites `(Y..X)::`, which can
include revisions forked from an intermediate task ancestor even when they are
not descendants of `X`. Stop if any revision in this set belongs to another
task or operator.

```bash
rewrite_scope="(main@origin..$candidate_change)::"
jj log -r "main@origin..$candidate_change" --reversed &&
jj log -r "$rewrite_scope" &&
jj rebase -b "$candidate_change" -o main@origin &&
jj status &&
task_conflicts="$(
  jj log --no-graph \
    -r "conflicts() & $rewrite_scope" \
    -T 'commit_id ++ "\n"'
)" &&
test -z "$task_conflicts" &&
jj log -r "$rewrite_scope" &&
jj log -r "exactly($candidate_change & main@origin::, 1)"
```

Resolve only owned, unambiguous file conflicts according to
`conflicts.md`. Ask about semantic or ownership ambiguity. Re-inspect the
candidate and every rewritten descendant. If the candidate tree changed,
repeat all affected `$finish-nix-change` validation and activation.

If the candidate was already a descendant, skip the rebase itself but still run:

```bash
jj log -r "exactly($candidate_change & main@origin::, 1)"
```

Do not run the whole rebase block in that case.

## 4. Move and push only main

Coordinate with every active workspace owner and pause Jujutsu mutations for
the final publication window. If a quiescent window cannot be established, stop
instead of racing another operator.

After the final range, diff, conflict, and validation audit, freeze the exact
validated version with its full commit ID. A Change ID follows later rewrites
and is therefore not precise enough for the final publication target:

```bash
candidate_commit="$(
  jj log --no-graph -r "exactly($candidate_change, 1)" \
    -T 'commit_id ++ "\n"'
)" &&
test -n "$candidate_commit" &&
jj log -r "$candidate_commit"
```

Move `main` to that exact commit without an allow-backwards option:

```bash
jj bookmark move main --to "$candidate_commit" &&
local_conflicts="$(jj bookmark list main --conflicted)" &&
remote_conflicts="$(
  jj bookmark list main --remote origin --conflicted
)" &&
test -z "$local_conflicts" &&
test -z "$remote_conflicts" &&
local_main_target="$(
  jj log --no-graph -r 'exactly(main, 1)' -T 'commit_id ++ "\n"'
)" &&
test "$local_main_target" = "$candidate_commit" &&
publication_op="$(
  jj --at-op=@ --ignore-working-copy op log --no-graph -n 1 \
    -T 'id ++ "\n"'
)" &&
test -n "$publication_op" &&
jj --config git.sign-on-push=false --at-op="$publication_op" git push \
  --remote origin --bookmark main --dry-run
```

The dry run must show exactly one intended forward update to `main`. Otherwise
stop without retrying or pushing another bookmark.

After a clean dry run, inspect the operation head without integrating concurrent
operations. Assert that it is still the frozen publication operation, that
`main` has one unconflicted target at the exact validated commit, and that
`main@origin` is unchanged from the final audit. If any check fails, this block
exits non-zero: stop, then repeat the final audit and dry run instead of pushing.

```bash
current_op="$(
  jj --at-op=@ --ignore-working-copy op log --no-graph -n 1 \
    -T 'id ++ "\n"'
)" &&
test "$current_op" = "$publication_op" &&
jj --at-op="$publication_op" bookmark list main --all-remotes &&
local_conflicts="$(
  jj --at-op="$publication_op" bookmark list main --conflicted
)" &&
remote_conflicts="$(
  jj --at-op="$publication_op" bookmark list main \
    --remote origin --conflicted
)" &&
test -z "$local_conflicts" &&
test -z "$remote_conflicts" &&
local_main_target="$(
  jj --at-op="$publication_op" log --no-graph \
    -r 'exactly(main, 1)' -T 'commit_id ++ "\n"'
)" &&
test "$local_main_target" = "$candidate_commit" &&
current_remote_main="$(
  jj --at-op="$publication_op" log --no-graph \
    -r 'exactly(main@origin, 1)' -T 'commit_id ++ "\n"'
)" &&
test "$current_remote_main" = "$remote_main_commit"
```

Only after that block succeeds, perform the push as a separate tool invocation.
Loading the frozen operation mechanically binds the push to the exact audited
local `main`; the remote lease still rejects an external remote race:

```bash
jj --config git.sign-on-push=false --at-op="$publication_op" git push \
  --remote origin --bookmark main
```

Do not add force, all-bookmark, or alternate-remote flags. If push is rejected
or remote state changed, stop, fetch, and repeat the complete audit; never
retry blindly.

## 5. Verify publication

```bash
jj bookmark list main --all-remotes &&
local_conflicts="$(jj bookmark list main --conflicted)" &&
remote_conflicts="$(
  jj bookmark list main --remote origin --conflicted
)" &&
test -z "$local_conflicts" &&
test -z "$remote_conflicts" &&
local_main_target="$(
  jj log --no-graph -r 'exactly(main, 1)' -T 'commit_id ++ "\n"'
)" &&
remote_main_target="$(
  jj log --no-graph -r 'exactly(main@origin, 1)' \
    -T 'commit_id ++ "\n"'
)" &&
test "$local_main_target" = "$candidate_commit" &&
test "$remote_main_target" = "$candidate_commit"
```

Confirm local and remote `main` agree at `candidate_commit`. Report both the
logical Change ID and the published commit ID with validation evidence. A
published error must be corrected by a new forward change and another
explicitly authorized publication.
