---
name: finish-nix-change
description: Validate, activate, and safely hand off edits in this NixOS and Home Manager repository. Use after any repository file was modified, before declaring completion or publication, and whenever asked to format, check, evaluate, build, test, switch, verify affected hosts, or recover from an activation begun by this workflow. Also use for validation or activation requests when no file was edited. Do not use for read-only analysis that requests neither repository edits nor validation or activation.
---

# Finish a Nix Change

Use `AGENTS.md` for repository scope and authorization. Use `$jj-guide` for
change ownership, history mutation, conflict handling, workspaces, bookmarks,
and remotes. This skill decides what evidence is required before an edit can be
handed off; it does not create publication authority.

Except for the emergency recovery entry below, complete `$jj-guide`'s preflight
before the first command here. Consume the owned diff and boundary established
there; return to it for every later Jujutsu status, diff, history, or conflict
operation. Recovery from an activation already begun is time-sensitive and
uses its recorded literal recovery point without first snapshotting or
inspecting the repository.

## Choose the entry mode

- **Edit handoff:** use the owned diff from `$jj-guide`, then follow every
  applicable section below.
- **Validation-only:** identify the user-requested target tree and host, or use
  the current working-copy tree and current host when unambiguous. Skip edit
  formatting and documentation-impact steps; run the requested check plus any
  prerequisite evidence needed to make it meaningful.
- **Activation-only:** identify the exact already-built target and current host.
  If the request names only a mutable current tree, evaluate and build it first
  through this skill. Record its literal store path, then read
  `activation-and-rollback.md`. Do not imply that an old validation result still
  applies to a different tree.
- **Recovery from this workflow:** skip `$jj-guide` preflight and go directly to
  the recovery section of the activation reference using the literal recovery
  point recorded before the activation. Do not rebuild or begin another
  activation first. If no reliable recovery point exists, stop and ask rather
  than guessing a generation.

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

Before an input mutation, and before validating a diff that affects another
host, a shared module, SSH, `flake.nix`, `flake.lock`, or a dependency, read
[scope-and-inputs.md](references/scope-and-inputs.md). Perform an authorized
lock-graph update before the no-update validation below, never as its side
effect.

## Run baseline validation

For documentation, comments, and formatting-only edits:

```bash
git diff --check
```

For `AGENTS.md` and skill documentation, verify that every relative Markdown
link resolves. Only when `.agents/skills/**` changes, also use `$skill-creator`,
run its validator for every added or changed skill, and parse YAML metadata.

For any Nix configuration edit, run in order:

```bash
nix fmt --no-update-lock-file -- <owned-existing-changed-file.nix>...
git diff --check
nix flake check --no-update-lock-file
```

Pass every owned, existing added/modified `.nix` file and renamed destination
explicitly; omit deleted or old renamed paths, and skip formatting when no
eligible path remains. Never run the repository-wide zero-argument formatter in
a shared working copy. After formatting, return to `$jj-guide` and re-read the
exact diff because formatting can touch more files than the initial edit. Stop
if `flake.lock` changed without the separately authorized input operation.

## Evaluate and build affected hosts

Use the actual import graph, not path names alone:

| Scope | Required evidence |
| --- | --- |
| `hosts/atlas/**` | Evaluate and fully build `atlas` |
| `hosts/legion-wsl/**` | Evaluate and fully build `legion-wsl` |
| A host's `home.nix` or private module | Evaluate and fully build that host |
| Shared module or shared input wiring | Fully build the current affected host; evaluate every other actual importer |
| Explicit dependency update | Fully build the current or explicitly targeted affected host; evaluate every other actual importer and report those not fully built |

Do not build every other host indiscriminately on the current machine. For each
host requiring local evaluation:

```bash
host='<host>'
attr=".#nixosConfigurations.$host.config.system.build.toplevel"
nix eval --no-update-lock-file "$attr.drvPath"
```

Separately, for each current or explicitly targeted host requiring a full
build:

```bash
host='<host>'
attr=".#nixosConfigurations.$host.config.system.build.toplevel"
system_toplevel="$(
  nix build --no-update-lock-file "$attr" --no-link --print-out-paths
)" &&
test -n "$system_toplevel" &&
nix path-info "$system_toplevel" &&
printf 'system_toplevel=%s\n' "$system_toplevel"
```

Copy the printed literal store path into the task record. Activation must use
that exact path for both temporary test and persistent switch; never rebuild
from a mutable repository path between those stages.

## Activate only when applicable

Pure documentation, comments, and formatting do not require activation.

For current-host NixOS or embedded Home Manager changes, and for an explicit
activation-only or workflow-recovery request, read and follow
[activation-and-rollback.md](references/activation-and-rollback.md). Low-risk
changes proceed through `nh os test`, task-specific behavior verification,
then `nh os switch`. High-risk categories require user confirmation before
the first activation.

Do not activate another host or use SSH unless the user explicitly requested
cross-machine work.

## Recheck after history or tree changes

If `$jj-guide` splits, squashes, rebases, resolves conflicts, or otherwise
changes the candidate tree after validation:

1. Inspect the resulting diff and scoped conflicts.
2. Repeat every validation whose input changed.
3. Repeat activation when the realized current-host tree changed materially.

A tree-preserving description-only rewrite does not invalidate Nix validation.

## Hand off evidence

Return to `$jj-guide` for the final status, exact diff, change boundary,
descendant, operation, and scoped-conflict checks. After its final diff review,
run `git diff --check` once more.

Before claiming completion, confirm:

- the final diff contains only intended files;
- all required checks, evaluations, and builds succeeded;
- activation and behavior verification either succeeded, were not applicable,
  or are reported explicitly as incomplete;
- documentation was updated where its audience-facing facts changed;
- `$jj-guide` has verified change descriptions, boundaries, and conflicts.

Report the logical Change ID or IDs, validation commands and outcomes,
activation status, behavior evidence, documentation impact, and any remaining
risk. Do not publish unless the user explicitly requested it; an authorized
publication continues through `$jj-guide`'s `references/publish-main.md` only
after this readiness gate passes.
