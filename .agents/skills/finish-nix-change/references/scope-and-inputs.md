# Host Scope and Flake Inputs

## Keep machine effects in scope

Default to the current host. A shared module can affect both configurations, so
identify every actual importer before validation. Evaluate another host when a
shared source affects it. This local, no-write evaluation does not access that
machine. Build another host only when the user explicitly made it a target; do
not activate, write to, or SSH into another machine without separate explicit
authorization.

## Apply an authorized input operation

When `flake.nix` adds, removes, or changes an input URL or `follows`
relationship, regenerate the lock graph as an explicit topology step before
baseline validation, then inspect both `flake.nix` and `flake.lock` to ensure no
unrelated input moved:

```bash
nix flake lock
```

When `AGENTS.md`'s explicit dependency-update authorization exists, use the
narrowest applicable command:

```bash
nix flake update <input-name>
nix flake update
```

Keep a dependency update in a dedicated, intentional, validated Jujutsu change.
Fully build the current or explicitly targeted affected host, evaluate every
other actual importer, and report any importer that was not fully built. The
state-version and credential invariants remain single-sourced in `AGENTS.md`.
