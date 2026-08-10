---
name: provision-nix-capability
description: Route requested tools and capabilities to the smallest correct declarative scope in this NixOS/Home Manager repository. Use when a user asks to install, add, enable, configure, remove, replace, or make a CLI, desktop app, development tool, shell integration, user service, or system service available, including requests such as “安装工具” or “添加软件”.
---

# Provision Nix Capability

Treat a request as declaring a reproducible capability, not as traditionally
installing a binary. Keep the persistent environment small, choose one package
provider for each target command, and let modules own the configuration that
belongs to them.

## Route the request

Classify the need before editing.

| Need | Default route |
| --- | --- |
| Run once | `nix run`; do not edit the repository. |
| Try several tools interactively | `nix shell`; do not edit the repository. |
| Project-specific toolchain | The project's flake/devShell with `nix develop` and, when appropriate, `direnv`; do not pollute the host profile. |
| Persistent user CLI or desktop app | Home Manager: use a suitable `programs.<name>` module when it supplies the needed package or configuration; otherwise use `home.packages`. |
| User-session daemon | Home Manager service or program module. |
| System daemon, hardware, PAM/udev/DBus, login-shell, or root capability | Prefer a NixOS module. Use `environment.systemPackages` only when a system-wide executable is genuinely needed and no module owns it. |

Treat an unqualified request to “install” a tool as persistent only when the
context makes that clear. Ask one concise question when the lifetime or scope
would materially change the result. Default to the current host; require an
explicit reason before changing a shared module or another host.

Treat a request to avoid host pollution as a request not to add a new
persistent provider. Audit and disclose an existing persistent provider, but
do not remove it without explicit authorization.

## Audit before selecting an owner

1. Search the repository for candidate declarations with `rg`. Treat this as a
   lead, not proof of duplication.
2. Evaluate the target configuration and inspect the effective providers:
   `environment.corePackages`, `environment.systemPackages`, the target user's
   `home.packages`, and the relevant `programs.<name>` or `services.<name>`
   options. Compare package output paths when names or variants are ambiguous.
3. Inspect the module implementation or the pinned option documentation when it
   is unclear whether enabling a module also adds its package. Never assume that
   every `programs.<name>.enable` has the same package behavior.
4. Check whether NixOS already provides the command as a core/default package.
   Do not add an explicit duplicate merely to make it visible.
5. Check generated configuration targets before enabling a Home Manager module.
   Preserve existing user-managed files; stop and present options rather than
   overwriting or moving them without authorization.

Define one owner as one **package provider for the same executable in the
target user's PATH**. A configuration-only module may coexist with that
provider. Treat NixOS core packages, a system daemon plus a separate user
client, and distinct wrapper commands as explicit exceptions; explain them in
the handoff.

If an existing provider already meets the request, make no package change. If a
new owner replaces an old one, remove the obsolete provider in the same change.

## Configure the chosen capability

- Prefer a first-class NixOS or Home Manager module over a raw package when it
  owns the requested configuration, service, or integration. Select a package
  variant through the module's `.package` option instead of adding a second raw
  package.
- Use `home.packages` for a persistent bare user executable with no useful
  module, or when a module would take over unwanted configuration.
- Enable only the integrations that the request or the currently configured
  environment needs. For example, enable shell integration only for active
  shells; do not turn on aliases, plugins, daemons, sync, or every shell by
  default.
- Keep system capabilities in NixOS modules. Refer to packages directly from a
  systemd unit when they are private runtime dependencies rather than making
  them global commands.
- Use the repository's pinned inputs. Do not use `nix-env`, `nix profile`,
  global language-package managers, a new overlay, a new flake input, or a
  `flake.lock` update merely to add one tool. Ask before an unfree-policy or
  source-topology change.
- Follow the repository's host → bundle → module placement rules. Do not create
  a shared module or bundle for a one-host request without a demonstrated shared
  need.

## Validate and hand off

For any persistent repository edit, read and follow
`.agents/skills/done-any-edit/SKILL.md`; it owns formatting, evaluation, build,
activation, commit, and push requirements.

Additionally verify that the requested command has the intended effective
provider after evaluation. After a successful activation on the current host,
check the actual command only when it materially validates the request.

Keep the normal handoff short: state the capability, its owner/scope, and
activation status. Add a quick-start command, alternatives, or trade-off notes
only when the user requests them or when a non-obvious choice affects use.
