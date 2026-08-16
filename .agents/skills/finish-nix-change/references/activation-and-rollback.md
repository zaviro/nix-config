# Activation and Rollback

Apply this only to the current machine after all required formatting, checks,
evaluation, and builds succeed. An explicit recovery from an activation already
begun by this workflow enters directly at **Recover only when activation began**
with the previously recorded literal recovery point. If no reliable recovery
point exists, report the missing prerequisite rather than guessing a generation.

## Contents

- Classify activation risk
- Preserve the agent control channel
- Record the recovery point
- Choose atomic or staged activation
- Test, explore, then finalize
- Activate when the control path is unaffected
- Recover only when activation began

## Classify activation risk

Judge confirmation from the activation's actual side effects, recoverability,
impact on the agent control channel, and risk of interrupting the user's work.
Proceed autonomously when the current-host effects are non-destructive,
recoverable, and proportionally safeguarded.

Request confirmation only when safe progress depends on the user's acceptance
of effects that cannot be verified and automatically recovered before control
may be lost, or on an unavoidable interruption of the user's live work. Treat
test activation and persistent switch as separate risk stages because their
effects can differ.

A literal recovery point, independent control-channel recovery, and bounded
health checks are prerequisites whenever those safeguards are material. Report
a missing prerequisite as a blocker. Disko execution requires a separately
authorized destructive workflow and is outside normal build, test, switch, and
recovery.

## Preserve the agent control channel

Before any test or activation step that can interrupt the current agent's
control path, establish recovery that does not depend on another tool call.

- Keep test activation, task-specific checks, persistent switch when
  applicable, failure restoration, and control-channel checks in one bounded
  transaction. Use one non-interactive invocation when checks are known in
  advance. A staged transaction may span tool calls only while its independent
  watchdog remains active and its hard deadline remains fixed.
- Arm recovery before disruption. Use an exit trap for normal failures and an
  independent watchdog for shell termination or loss of the control channel.
- Keep the watchdog active until task-specific behavior and control-channel
  health checks verify either the successful switched state or the recovered
  original state. Only then disarm it.

Use [`../scripts/guarded-activate`](../scripts/guarded-activate) for this guarded
transaction. It snapshots its recovery payload into the caller's runtime
directory, arms a transient systemd timer before activation, bounds each step,
and uses the same exact recovery implementation from both its exit trap and the
independent timer.

When verification deliberately disrupts service or connectivity state, record
that state before disruption, restore it on failure, and include state-specific
behavior and control-channel checks in the protected invocation.

## Record the recovery point

Receive the exact `system_toplevel` store path printed by the completed build.
Run this as one command, then copy the printed literal target and generation
into the task record before any required confirmation or starting activation.
Shell variables do not survive separate tool calls; in later commands, set them
again from those recorded literals and revalidate them.

```bash
system_toplevel='<literal-store-path-from-completed-build>'
current_generation="$(readlink /nix/var/nix/profiles/system \
  | sed -n 's/^system-\([0-9]\+\)-link$/\1/p')"
test -x "$system_toplevel/bin/switch-to-configuration" &&
test -n "$current_generation" &&
printf 'system_toplevel=%s\ncurrent_generation=%s\n' \
  "$system_toplevel" "$current_generation"
```

This pins validation, temporary activation, behavior verification, and
persistent activation to one immutable build output.

## Choose atomic or staged activation

Use atomic mode for deterministic checks that can be designed before test
activation. It performs test, health checks, switch, post-switch checks, and
recovery in one invocation. Use staged mode when observations from the test
activation must guide multiple read-only commands before deciding whether to
switch. Do not use staged mode merely to postpone obvious checks.

Atomic mode and staged `finalize` or `rollback` require a read-only health
command after `--`. The helper appends one phase argument on every invocation:

- `test`: verify the temporary target and the control channel before switching.
- `switched`: verify the persistent target and the control channel.
- `recovered`: verify restored task-specific and control-channel state after a
  failure.

It also exports `GUARDED_ACTIVATE_PHASE`, `GUARDED_ACTIVATE_TARGET`,
`GUARDED_ACTIVATE_RECOVERY_TARGET`, and
`GUARDED_ACTIVATE_RECOVERY_GENERATION`; staged health checks also receive
`GUARDED_ACTIVATE_TRANSACTION`. Branch on the phase when desired and recovery
states differ. Keep the command read-only. If recovery requires an additional
idempotent state restoration, pass a self-contained executable with
`--recovery-hook`; it runs as root after the exact generation is restored and
before recovery verification.

```bash
system_toplevel='<recorded-literal-store-path>'
current_generation='<recorded-literal-generation>'

.agents/skills/finish-nix-change/scripts/guarded-activate \
  --target "$system_toplevel" \
  --recovery-generation "$current_generation" \
  -- bash -c '
    phase="$1"
    case "$phase" in
      test | switched)
        # Verify the requested behavior and control channel.
        ;;
      recovered)
        # Verify the original behavior and control channel.
        ;;
    esac
  ' guarded-health-check
```

The helper refuses to start when the active system and persistent profile do
not both match the recorded recovery generation. It verifies that `nh os test`
does not change the persistent profile, verifies both active and persistent
links after `nh os switch`, and leaves the watchdog armed if recovery cannot be
verified.

## Test, explore, then finalize

Start a staged transaction with the exact target and recovery generation. The
watchdog lease must exceed one bounded activation or check. The hard limit caps
the whole exploratory window, including renewals:

```bash
system_toplevel='<recorded-literal-store-path>'
current_generation='<recorded-literal-generation>'

.agents/skills/finish-nix-change/scripts/guarded-activate test \
  --target "$system_toplevel" \
  --recovery-generation "$current_generation" \
  --watchdog-seconds 180 \
  --max-seconds 900
```

Record the printed `transaction` ID. The command returns with the target test
active, the persistent profile unchanged, and recovery armed. Before every
later staged operation, retain the literal ID and inspect the transaction when
state may have changed. `status` reports the watchdog as `active`, `recovering`,
or `inactive`:

```bash
transaction='<recorded-transaction-id>'
.agents/skills/finish-nix-change/scripts/guarded-activate status \
  --transaction "$transaction"
```

Run agent-selected, read-only exploratory commands while the lease is active.
Use their outputs to choose further checks. Renew only when more exploration is
necessary; renewal is refused if it would exceed the original hard deadline:

```bash
.agents/skills/finish-nix-change/scripts/guarded-activate renew \
  --transaction "$transaction"
```

Once the evidence is sufficient, finalize with a read-only health command. The
helper rechecks the test phase, switches the exact target, checks the switched
phase, and then disarms recovery:

```bash
.agents/skills/finish-nix-change/scripts/guarded-activate finalize \
  --transaction "$transaction" \
  -- bash -c '
    phase="$1"
    case "$phase" in
      test | switched)
        # Verify requested behavior and the control channel.
        ;;
      recovered)
        # Verify restored behavior and the control channel.
        ;;
    esac
  ' guarded-health-check
```

If exploration disproves the change or the task should stop, explicitly
restore the pinned generation and verify recovery:

```bash
.agents/skills/finish-nix-change/scripts/guarded-activate rollback \
  --transaction "$transaction" \
  -- bash -c '
    phase="$1"
    test "$phase" = recovered
    # Verify restored behavior and the control channel.
  ' guarded-recovery-check
```

If the agent disconnects or neither `finalize` nor `rollback` runs before the
lease expires, the systemd watchdog restores the pinned generation without a
later tool call. A missing or inactive watchdog is never renewable; the helper
restores instead. Staged transaction commands do not modify Jujutsu changes or
descriptions.

## Activate when the control path is unaffected

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
nh os test "$system_toplevel"
```

`nh os test` performs a real but non-persistent activation. After it succeeds,
the agent independently chooses and runs proportional task-specific checks from
the requested outcome and actual effects. Direct evidence required for safety
must succeed before `switch`. For lower-risk effects that cannot be directly
automated, successful test activation plus proportional smoke checks is
sufficient; report the verification depth and remaining uncertainty.

After successful behavior verification:

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
nh os switch "$system_toplevel"
```

Do not use `sudo nh os` or `nh home switch`; Home Manager is embedded in the
NixOS configuration.

## Recover only when activation began

If validation or a pre-activation check fails, the system was not changed and
must not be rolled back.

To leave a successful test-only activation, or when test activation began and
then failed outside a completed guarded transaction, reactivate the recorded
persistent generation:

```bash
current_generation='<recorded-literal-generation>'
recovery_system="/nix/var/nix/profiles/system-$current_generation-link"
test -x "$recovery_system/bin/switch-to-configuration" &&
sudo "$recovery_system/bin/switch-to-configuration" switch
```

If `nh os switch` began activation and then failed, use the recorded literal:

```bash
current_generation='<recorded-literal-generation>'
test -n "$current_generation" &&
nh os rollback --to "$current_generation"
```

If any persistent switch began then failed and `nh os rollback` is unavailable
or cannot start, restore both the persistent system profile and the active
system without `nh`. Use the exact recorded generation, not “previous,” because
a partial failure may already have changed profile ancestry:

```bash
current_generation='<recorded-literal-generation>'
recovery_link="/nix/var/nix/profiles/system-$current_generation-link"
test -e "$recovery_link" &&
sudo nix-env --profile /nix/var/nix/profiles/system \
  --switch-generation "$current_generation" &&
sudo "$recovery_link/bin/switch-to-configuration" switch
```

Stop and report immediately if rollback fails. Do not improvise a Disko,
bootloader, network, or destructive recovery.

On `legion-wsl`, run the same `test` then `switch` sequence only while
operating on that target machine. If `nh` is unavailable there, use the
explicit host fallback, retaining the behavior-verification gate:

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
sudo nixos-rebuild test --store-path "$system_toplevel"
```

Run and require proportional task-specific behavior verification to succeed.
For changes that do not affect the control path, persistent activation may then
run as a later, separate command:

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
sudo nixos-rebuild switch --store-path "$system_toplevel"
```

For control-path changes, instead keep fallback test, verification, switch, and
recovery in one protected invocation as required above.

If the user explicitly authorizes activation on another machine, establish its
exact target, persistent generation, connectivity fallback, and rollback command
before remote access. Do not apply this local recovery recipe remotely by
assumption.
