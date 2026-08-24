---
name: clash-verge-runtime-change
description: Validate and safely activate Clash Verge Rev and Mihomo runtime changes, including isolated configuration tests, complete UI reload, behavior verification, and runtime-aware rollback. Use for Nix or runtime work that can affect Clash profiles, generated configuration, DNS, rules, proxy selection, TUN, routing, or the running core. Do not use for unrelated Nix changes or read-only questions that require no runtime workflow.
---

# Change Clash Verge Runtime Safely

Use `AGENTS.md` for repository scope and authorization. Use `$jj-guide` before
repository edits or Jujutsu operations. After repository edits, use
`$finish-nix-change` for formatting, Nix evaluation and build, generic NixOS
activation recovery, completion evidence, and the authorized `next`
synchronization.

This skill owns the application-specific part: proving what Clash Verge
generates and Mihomo actually runs, and restoring that state after a failed
target. It does not duplicate or replace `finish-nix-change`'s system-generation
transaction.

## Apply only to the affected runtime

Use this skill when the exact requested work can change any of these:

- managed Merge or Script profile inputs;
- the generated `clash-verge.yaml` or profile enhancement pipeline;
- DNS, rule providers, routing, proxy-group selection, TUN, or transport stack;
- the Clash Verge UI or Mihomo core package, service, listeners, or controller.

Do not route ordinary Nix completion through this skill merely because Clash
Verge is installed on the host. A configuration-only review that will not test,
deploy, recover, or inspect runtime behavior may use ordinary read-only analysis.

## Keep all three state layers visible

Treat these as distinct states:

1. NixOS and embedded Home Manager deploy the managed profile inputs.
2. A complete Clash Verge UI start runs the enhancement pipeline and writes the
   application-owned generated configuration.
3. Mihomo loads that generated result and owns the live DNS, TUN, routes,
   listeners, controller state, and connections.

Neither Nix deployment nor generation rollback alone advances or restores all
three layers. A core-only restart can reuse stale generated state. Target
application and rollback therefore both require a complete UI restart whenever
the changed inputs can affect the running configuration.

Do not edit the live generated `clash-verge.yaml` as the implementation. For
safe pre-deployment experimentation, derive an isolated copy instead.

## Select evidence by risk

- For DNS, Script, rules, or profile transformation logic, read
  [references/isolated-validation.md](references/isolated-validation.md) and
  validate an isolated Mihomo instance before touching the live path whenever
  that can provide meaningful evidence.
- For target deployment, UI/core changes, live TUN or routing tests, or recovery
  from an activation already begun, read
  [references/live-activation-and-recovery.md](references/live-activation-and-recovery.md).
- Keep DNS/rule logic separate from TUN, transport-stack, or system-routing
  changes when isolation cannot prove the latter. For a risky combination,
  test one independently reviewable variable at a time.

Isolation is a rejection gate, not proof of live TUN, DNS hijack, system
routing, or persisted selector behavior. Complete current-host work through the
protected live workflow after `$finish-nix-change` has produced the exact built
target.

## Preserve authorization boundaries

This skill does not authorize activation on another host, moving `main`,
publishing a bookmark, deleting a handoff source, changing proxy selections,
or editing application-owned live output. It also does not turn a Clash-specific
restart into a default step for unrelated `finish-nix-change` work.
