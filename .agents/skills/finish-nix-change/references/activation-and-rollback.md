# Activation and Rollback

Apply this only to the current machine after all required formatting, checks,
evaluation, and builds succeed. An explicit recovery from an activation already
begun by this workflow enters directly at **Recover only when activation began**
with the previously recorded literal recovery point. If no reliable recovery
point exists, stop and ask rather than guessing a generation.

## Contents

- Decide whether confirmation is required
- Record the recovery point
- Test, verify behavior, then switch
- Recover only when activation began

## Decide whether confirmation is required

Request confirmation before activating changes to:

- Disko or disk layout;
- filesystems, mounts, swap, or storage availability;
- bootloader, kernel, or initrd;
- NetworkManager, Tailscale, SSH, firewall, or network reachability;
- authentication, PAM, authorization, or privilege escalation;
- login shells or user/session startup;
- display manager, desktop session, compositor, or graphics stack;
- WSL integration, interop, automount, or default-user behavior.

Do not run Disko scripts as part of normal build, test, switch, or recovery.

## Record the recovery point

Receive the exact `system_toplevel` store path printed by the completed build.
Run this as one command, then copy the printed literal target and generation
into the task record before requesting confirmation or starting activation.
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

## Test, verify behavior, then switch

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
nh os test "$system_toplevel"
```

`nh os test` performs a real but non-persistent activation. Design and run a
task-specific check that proves the requested behavior is active. Do not use a
generic successful exit code as behavior evidence.

If meaningful behavior verification cannot be performed, report it as
incomplete and do not proceed to `switch`.

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

To leave a successful temporary test activation, or when test activation began
and then failed, reactivate the recorded persistent generation:

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

Run and require the task-specific behavior verification to succeed. Only then
may persistent activation run as a later, separate command:

```bash
system_toplevel='<recorded-literal-store-path>'
test -x "$system_toplevel/bin/switch-to-configuration" &&
sudo nixos-rebuild switch --store-path "$system_toplevel"
```

If the user explicitly authorizes activation on another machine, establish its
exact target, persistent generation, connectivity fallback, and rollback command
before remote access. Do not apply this local recovery recipe remotely by
assumption.
