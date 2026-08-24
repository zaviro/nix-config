# Isolated Mihomo Validation

Read this reference for changes to DNS, Script, rules, providers, profile
transformation, or other logic that can be meaningfully rejected before it
touches the live network path.

## Derive the test from reality

Start from the current generated configuration and the same Mihomo executable,
rule data, and persisted proxy-group choices that the formal instance uses. Do
not construct an unrelated minimal configuration whose success would say
little about the requested change.

Place the copied configuration and data in a private runtime directory. The
copy can contain subscription credentials or proxy details, so use restrictive
permissions, never print the complete file, and remove the exact temporary
files at the end of the bounded test. Before starting the isolated core, arm an
exit trap that terminates it, waits for it to exit, and removes the validated
private directory on success, ordinary failure, or interruption.

Change only the owned candidate behavior plus the isolation controls:

- disable TUN;
- select unused mixed, DNS, and controller listeners;
- use a separate data, cache, ruleset, and Unix-controller location;
- do not modify system DNS, routes, the live generated configuration, or the
  formal Clash Verge process;
- mirror relevant selector choices through the isolated Controller API rather
  than silently testing a different exit.

Check candidate listeners before launch, but treat successful binding by the
isolated core as the authority because availability checks race with later
binds. A bind failure rejects the isolated run; never fall back to a live
listener or stop the formal instance to free one.

Use one-off tooling according to repository policy when parsing YAML or issuing
DNS probes; do not persist packages merely for the test.

## Prove semantics, not only syntax

First require Mihomo's configuration test to accept the isolated target. Then
use representative probes chosen from the requested behavior, for example:

- a domestic domain and an IP-classified domestic destination that should be
  direct;
- a non-CN domain that should use the ordinary selector;
- a service with an explicit policy group, such as Google or an AI provider;
- DNS responses through the isolated listener;
- HTTPS outcomes through the isolated mixed proxy;
- Controller logs showing the actual matched rule and final policy group.

Preserve explicit fallback rules that the current system intentionally relies
on unless the requested change replaces them with verified equivalent
behavior. An isolated pass does not justify `no-resolve` on an IP ruleset when
real traffic requires DNS resolution before that rule can match.

## Keep the conclusion narrow

An isolated pass supports the copied profile transformation, DNS path, rule
match, proxy reachability, and HTTPS behavior that were directly observed. It
does not prove:

- live TUN stack behavior or DNS hijack;
- host route ownership or interaction with NetworkManager;
- UI regeneration, Home Manager deployment, or persisted selectors;
- transport options whose effect depends on the real TUN path.

Keep those changes in a separate semantic boundary and use the protected live
workflow. When a combined live test fails, reduce it to one independently
testable variable rather than repeatedly deploying the same bundle.
