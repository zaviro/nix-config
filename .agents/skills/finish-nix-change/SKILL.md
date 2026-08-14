---
name: finish-nix-change
description: Validate and hand off NixOS and Home Manager repository changes. Use after repository edits, before publishing local changes, or for explicit formatting, evaluation, build, activation, affected-host verification, and activation-recovery requests. Do not use for read-only analysis requiring none of these actions.
---

# Finish a Nix Change

Use `AGENTS.md` for repository scope and authorization. Use `$jj-guide` for
change ownership, history mutation, conflict handling, workspaces, bookmarks,
and remotes. This skill decides what evidence is required before an edit can be
handed off; it does not create publication authority.

Except for recovery from an activation already begun, consume the owned diff
and boundary established by `$jj-guide`; return to it for later version-control
operations. For validation-only work, identify the exact requested tree and
host before selecting evidence.

## Inspect a completed edit

Use the exact owned diff from `$jj-guide` to classify the edit as
documentation-only, Nix configuration, host-specific, shared across hosts,
flake input topology, or dependency update. Stop if it contains unrelated files
or an unresolved ownership boundary and return to `$jj-guide`.

Check documentation impact before validation:

- Update `README.md` only when human-facing repository facts, public flake
  interfaces, major capabilities, or operating entrypoints changed.
- Update `AGENTS.md` only when stable repository structure, authorization, or
  mandatory routing changed.
- Update a skill only when its task-specific workflow or knowledge changed.
- Do not create duplicate explanation files or document a pure internal
  refactor as a behavior change.

Before an input mutation or work affecting another host, a shared module, SSH,
`flake.nix`, `flake.lock`, or a dependency, read
[scope-and-inputs.md](references/scope-and-inputs.md).

## Run baseline validation

For documentation, comments, and formatting-only edits:

```bash
git diff --check
```

For `AGENTS.md` and skill documentation, verify that every relative Markdown
link resolves. Only when `.agents/skills/**` changes, also use `$skill-creator`,
run its validator for every added or changed skill, and parse YAML metadata.

For Nix configuration edits or explicit formatting, evaluation, or build work,
read [validation-and-build.md](references/validation-and-build.md). For
current-host NixOS or embedded Home Manager edits, activation is normal
completion evidence: proceed through test, agent-selected behavior verification,
and switch according to the activation reference's risk classification. For
current-host activation, activation-only work, or
recovery from an activation already begun, read
[activation-and-rollback.md](references/activation-and-rollback.md). Recovery
uses its recorded literal recovery point directly; do not inspect or rebuild a
mutable tree first. For other activation-only work, first use
[validation-and-build.md](references/validation-and-build.md) when no exact,
already-built target is available. Pure documentation, comments, and formatting
do not require activation.

## Recheck after history or tree changes

If `$jj-guide` splits, squashes, rebases, resolves conflicts, or otherwise
changes the candidate tree after validation:

1. Inspect the resulting diff and scoped conflicts.
2. Repeat every validation whose input changed.
3. Repeat activation when the realized current-host tree changed materially.

A tree-preserving description-only rewrite does not invalidate Nix validation.

## Hand off evidence

Return to `$jj-guide` for the final status, exact diff, change boundary,
descendant, and scoped-conflict checks. After its final diff review, run
`git diff --check` once more.

Before claiming completion, confirm:

- the final diff contains only intended files;
- all required checks, evaluations, and builds succeeded;
- activation and behavior verification either succeeded, were not applicable,
  or are reported explicitly as incomplete;
- documentation was updated where its audience-facing facts changed;
- `$jj-guide` has verified change descriptions, boundaries, and conflicts.

Report the logical Change ID or IDs, validation outcomes, activation status,
behavior evidence, documentation impact, and remaining risk. Do not publish
unless the user explicitly requested it; publication continues through
`$jj-guide` only after this gate passes.
