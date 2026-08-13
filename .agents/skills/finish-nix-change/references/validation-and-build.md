# Validate and Build Nix Changes

Use this reference for Nix configuration edits and explicit formatting,
evaluation, or build requests. Apply authorized input changes from
[scope-and-inputs.md](scope-and-inputs.md) before no-update validation.

## Format and check

Run in order:

```bash
nix fmt --no-update-lock-file -- <owned-existing-changed-file.nix>...
git diff --check
nix flake check --no-update-lock-file
```

Pass every owned, existing added or modified `.nix` file and renamed destination
explicitly; omit deleted and old renamed paths. Skip formatting when none
remain. Do not run the repository-wide zero-argument formatter in a shared
working copy.

After formatting, return to `$jj-guide` and inspect the exact diff because the
tree may have changed. Stop if `flake.lock` moved without the separately
authorized input operation.

## Select affected hosts

Use the actual import graph rather than path names alone:

| Scope | Required evidence |
| --- | --- |
| `hosts/atlas/**` | Evaluate and fully build `atlas` |
| `hosts/legion-wsl/**` | Evaluate and fully build `legion-wsl` |
| A host's `home.nix` or private module | Evaluate and fully build that host |
| Shared module or shared input wiring | Fully build the current affected host; evaluate every other actual importer |
| Explicit dependency update | Fully build the current or explicitly targeted affected host; evaluate every other actual importer and report those not fully built |

Do not build every other host indiscriminately on the current machine.

For each host requiring local evaluation:

```bash
host='<host>'
attr=".#nixosConfigurations.$host.config.system.build.toplevel"
nix eval --no-update-lock-file "$attr.drvPath"
```

For each current or explicitly targeted host requiring a full build:

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

Record the printed literal store path. If activation applies, pass that exact
path to [activation-and-rollback.md](activation-and-rollback.md); do not rebuild
from a mutable repository tree between test and switch.
