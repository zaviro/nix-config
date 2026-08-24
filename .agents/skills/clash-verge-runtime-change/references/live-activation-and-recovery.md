# Live Activation and Runtime Recovery

Read this together with
[`finish-nix-change` activation and rollback](../../finish-nix-change/references/activation-and-rollback.md).
The generic reference owns the exact NixOS target, generation restoration,
watchdog, transaction phases, and activation commands. This reference supplies
the Clash Verge application steps and health semantics inside that transaction.

## Record the complete recovery point

Before target deployment, record all state needed to distinguish the target
from the recovered runtime:

- exact active and persistent NixOS generation and built target;
- whether the Clash Verge UI was active and how it was launched;
- hashes or exact identities of the managed Merge and Script inputs;
- generated values relevant to the diff;
- controller socket, listeners, UI and core processes, TUN state, and routes;
- persisted selections whose stability is part of the requested behavior;
- application-owned persistent state that the planned UI start or test can
  change and that must be restored on failure;
- representative stable connectivity outcomes.

Clash Verge service mode can run the UI as the ordinary user while its Mihomo
core is owned by a privileged service. Discover both independently; do not
assume a user-scoped process query finds the core.

Before arming recovery, verify the ordinary user's UID, runtime directory,
session bus, discovered unit and process lifecycle, every absolute helper path,
and the recovered health command. Do not begin from an unrecorded test-active
state: first follow the generic activation reference to restore or otherwise
establish matching active and persistent recovery state.

## Make UI restart a protected application step

Use
[`guarded-activate`](../../finish-nix-change/scripts/guarded-activate) with a
self-contained recovery hook before `nh os test` deploys the target inputs.
After the target test activation and while the watchdog is active:

1. Verify that Home Manager deployed the expected managed profile inputs.
2. Stop the discovered autostart unit when it owns the UI, terminate any
   remaining independently launched UI, and wait for both the process and unit
   lifecycle to settle before starting it again.
3. Start the complete UI as the ordinary user, not merely the Mihomo core.
4. Wait for a new UI, the service-mode core, controller, generated
   configuration, listeners, TUN, and routes to reach the target state.
5. Run the read-only target health command before finalizing the switch.

Discover the current unit and process identities rather than treating one
historical unit name or PID ownership model as universal. A unit may report
inactive while a manually launched UI still exists, or remain deactivating
briefly after the process exits. Wait for the observed lifecycle; do not race a
new start against it.

Health commands passed to `guarded-activate` remain read-only. The planned UI
restart is a separate protected application step inside the same bounded
transaction.

`guarded-activate` intentionally has no target-side application hook. When a
target UI mutation is required, use an outer bounded caller with this exact
ownership shape: start a staged test transaction, perform the planned UI
stop/start, run read-only target health, and finalize. Its exit trap must request
staged rollback when any step after `test` fails; the independently snapshotted
recovery hook remains the fallback when the caller or control channel dies.

If the UI was inactive before the transaction, starting it for live validation
is an additional desktop and network side effect. Apply the generic activation
risk classification before doing so, and restore the inactive state after a
temporary test unless the user authorized leaving it active.

## Keep recovery hooks genuinely self-contained

The recovery hook runs as root after the exact recovery generation has been
restored and before recovered health verification. Root and transient systemd
units can have a minimal `PATH` that differs from the agent shell.

- Resolve every non-shell command to an executable absolute path before arming
  recovery; this includes helpers such as `jq`, `yq`, `curl`, and user-session
  control commands.
- Make the hook executable and include all state it needs before passing it to
  `guarded-activate`; the helper snapshots it into the transaction payload.
- Address the ordinary user's systemd manager with its runtime directory and
  bus explicitly when the hook runs as root.
- If the UI was originally inactive, preserve that state instead of starting
  it during recovery.
- If it was active, perform the same complete UI stop/start and wait for the
  recovered controller and generated configuration. A core-only restart is not
  recovery.
- Restore any recorded application-owned persistent state that the target test
  actually changed. Do not copy or overwrite the entire application database by
  default; scope restoration to the state required by the behavior contract.

Do not begin live activation when either target or recovered UI state cannot be
restored and checked without a later agent call.

## Budget the transaction as one bounded operation

Prefer one non-interactive invocation containing test activation, target UI
restart, deterministic probes, finalize, switched probes, and failure rollback.
This avoids consuming a staged watchdog lease during model or tool round trips.

When staged exploration is genuinely required:

- set the lease and hard deadline above the worst-case sum of activation, UI
  shutdown/startup, configuration generation, every retry, and recovery;
- inspect status and renew before another bounded operation, not after the
  existing lease is nearly exhausted;
- give every invocation that mutates the UI an exit path that explicitly asks
  the staged transaction to roll back;
- leave the independent watchdog as the fallback for shell termination or
  control-channel loss.

If the watchdog enters `recovering`, do not race it with another target or
restart. Observe recovery until it succeeds or reports a concrete failure.

Each transaction recovers to its recorded, already accepted persistent stage.
If independently landing an earlier change is intentional, a later variable
test can use that accepted generation as its recovery point and must report that
choice. If the requested result must be atomic, do not persist an intermediate
stage; keep the original generation as the recovery point for the combined
target.

## Verify meaning rather than serialization

For `test` and `switched`, require phase-specific evidence for the target. For
`recovered`, require the recorded recovery values instead. Check at least:

- managed input identity and the relevant generated configuration;
- Controller API values for TUN, transport, listeners, and other owned fields;
- UI and core presence with their actual ownership model;
- DNS response, TUN interface, and route ownership when affected;
- representative HTTPS and, when useful, Controller rule-match logs.

Read formal selector choices and verify their persistence without changing
them. Selector mutation is permitted only inside the isolated Controller when
mirroring the recorded formal choice; a live selector switch is not a health
probe unless the user separately authorized it.

Application regeneration may normalize equivalent data, such as representing
an omitted fallback list as an empty list. Compare the semantic invariant when
serialization is not itself the requested behavior.

Separate health evidence into:

- **hard recovery invariants:** generation, inputs, generated values,
  controller, processes, TUN/routes, DNS, and multiple stable representative
  destinations;
- **requested behavior gates:** endpoints or policy groups whose behavior is
  the purpose of the change;
- **volatile observations:** a single provider or proxy node that can fail
  while the rest of the recovered network is healthy.

Use bounded retries. A volatile observation remains evidence and must be
reported, but it should not keep an otherwise proven recovery looping forever
unless that endpoint is the requested behavior gate. Account for every retry
in the watchdog budget.

Include the expected network interruption, active connection loss, and desktop
UI restart in the generic activation risk decision. The fact that rollback is
automated does not make those user-visible effects irrelevant.

After test evidence succeeds, finalize the exact target and repeat the same
target invariants in `switched`. If target behavior fails, restore the literal
recovery generation, perform the complete recovered UI restart, verify the
recovered application runtime, and stop deploying that combined target. Split
the candidate and isolate one variable before another live attempt.
