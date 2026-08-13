# Decide Whether to Fold a Correction

Use this case when a correction appears related to another local change. Treat
`main` as the stable boundary and owned, unpublished changes after it as a
mutable patch stack. Use history editing to improve logical ownership,
dependency order, validity at each stack state, and reviewability. Development
chronology alone is neither a reason to fold nor a reason to retain a change.

Jujutsu's operation log can recover local rewrites, but it is not pushed as the
Git history on GitHub. Preserve intentional evolution with a distinct landing
or rollback decision; do not preserve routine correction discovery merely to
document the work log.

## Test separate landing value

Discovery timing does not create a change boundary. A later request, real use,
test failure, review, new evidence, agent mistake, or failed attempt has no
independent value by itself. It matters only when it reveals a new requirement,
behavior, migration step, or decision intended to land separately.

Judge the resulting patches with a counterfactual test:

- Would a maintainer reasonably land the owner without the correction as an
  intentional repository state?
- Does the correction add behavior, a decision, or a migration step that a
  maintainer could reasonably omit or revert while retaining the owner?
- Does a separate boundary clarify a real dependency or choice rather than the
  chronology of implementation or review?

Keep the correction separate only when the owner remains an intentional state
without it and the correction has a distinct landing or rollback decision. The
correction may depend on the owner; dependency alone is not a reason to fold.
Being technically reviewable, testable, or revertible is not enough. Agent work
logs, review iterations, and the desire to show how a patch was discovered are
not lasting causal value.

## Find the possible owner

Record the task Change ID, then inspect the unpublished ancestor stack and the
relevant diffs:

```bash
fix_change='<task-change-id>'
jj log -r "main..$fix_change" --reversed
jj diff --git -r "$fix_change"
jj log -r "main..$fix_change-" --stat
```

Narrow candidate owners by the behavior, files, and lines the fix changes.
Inspect each plausible candidate with an explicit Change ID. Chronological
proximity, a shared file, or a `fix` description alone does not establish
ownership.

## Decide whether to fold

First establish the safety prerequisites: every rewritten change is owned,
mutable, unpublished, and understood; the combined patches and affected
descendants remain valid; and their descriptions can remain accurate.

Within that safe set, fold by default when the correction only makes an existing
patch accurate, complete, or easier to review. Keep it separate only when it
passes the separate-landing test above, such as a separately selectable
behavior, changed requirement, or intentional migration step. Timing, a shared
file, or a `fix` description do not decide the boundary.

If different parts belong to different owners, split them first or use an
audited `absorb` workflow instead of forcing the whole correction into one
change.

## Fold and verify

Before mutating history, inspect the exact owner-to-tip descendants and the
operation baseline. Then read [changes.md](changes.md) and use its explicit
"Squash a correction into its owner" workflow. A non-adjacent squash rebases
descendants, so verify afterward that:

- the correction Change ID disappeared or became empty as expected;
- the owner contains exactly the combined semantic unit;
- every descendant retains its original scope and description;
- no scoped conflicts were introduced;
- the working-copy tip still has the intended tree.

Return to `$finish-nix-change` for any validation invalidated by the rewritten
owner or descendants. An unchanged final tip does not by itself prove that the
rewritten owner remains valid as its own stack state.
