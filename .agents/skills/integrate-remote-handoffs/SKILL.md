---
name: integrate-remote-handoffs
description: Discover, audit, adapt, validate, and optionally retire one or more handoff candidates backed by live remote refs. Use for explicit integrate-remote-handoffs invocations or when temporary branches, bookmarks, or refs from another machine, cloud workspace, fork, or agent must be consumed into authoritative local work.
---

# Integrate Remote Handoffs

Consume remote-backed implementation proposals without treating them as
authoritative local solutions. Delegate version-control mechanics, validation,
deployment, activation, and recovery to repository-local instructions.

## Resolve the minimal invocation

Accept zero or more refs, URLs, or `ref@oid` locators as optional invocation
text. Resolve candidates in this order:

1. Explicit locators.
2. The latest handoff receipt in the conversation.
3. Exactly one candidate identified by repository remote convention.

A ref alone is sufficient. Infer its base, diff, and validation policy. Ask for
an exact locator only when no candidate or several ambiguous candidates remain.

Record every live candidate ref and object ID, its actual base, and the intended
local integration tip. An explicit OID pins the request; ask before substituting
a different live tip.

Integration permits live lookup, exact fetch, owned local changes, and
repository-authorized validation. Publication, source deletion, force update,
cross-machine writes, deployment, and activation require user or repository
authority.

## Triage quickly and in parallel

Compare each candidate with its common ancestor, local unpublished work, and
the other candidates. Inspect the complete diff and screen for:

- path, rename, delete, generated-file, and textual overlap;
- shared imports, consumers, services, and user-visible behavior;
- credentials, licenses, locks, migrations, destructive effects, and control
  channels;
- assumptions that can differ between producer and consumer environments.

Use one read-only reviewer per non-trivial independent candidate when that
reduces latency, plus a cross-candidate review when shared consumers are not
obvious. Pin every review to exact OIDs. Keep baseline ownership, mutations,
user questions, and final synthesis with the coordinating agent.

Treat a clear, low-risk set as the fast path: integrate it promptly and let the
version-control system expose textual conflicts. Escalate the audit only for
ambiguous intent, material interaction, risky effects, unclear ownership, or a
failed combined check.

Serialize mutation by default. Parallel writers require repository-supported
workspace isolation and disjoint ownership.

## Choose boundaries and adapt locally

Preserve separate changes when they can reasonably land or roll back alone.
Apply dependencies in order; combine only inseparable intent. An intentional
merge is appropriate only when independent ancestry is itself useful, not
merely to share one expensive check.

Prefer repository-native copy or replay operations that preserve the remote
proposal while creating owned local changes. Continue the same change identity
only when source ownership, mutability, and repository policy make that intent
explicit.

For a straightforward replay, record only intentional differences from the
source. Use a full preserved/adapted/omitted coverage map when splitting,
dropping, or materially translating source behavior. An unexplained material
omission is an integration failure.

Resolve technical conflicts autonomously when one repository-compliant answer
preserves the behavior contract. Keep compatibility fixes in the boundary whose
behavior requires them.

## Validate through a feedback loop

Run boundary-local formatting and cheap checks, then validate the exact final
tree according to repository policy. Share an expensive final check only when
it reaches every affected consumer, no intermediate runtime observation is
required, and candidate-specific behavior remains attributable.

When evidence fails, classify the cause as source proposal, local adaptation,
candidate interaction, or environment. Fix the owning boundary and rerun only
checks whose inputs changed, plus the required final interaction check. Continue
autonomously while intent remains clear, scope is unchanged, and recovery is
available.

## Ask only at material decision gates

After bounded read-only investigation, ask one focused question when:

- the repository, candidate, integration tip, or local ownership is ambiguous;
- a pinned OID differs from the live ref;
- resolution requires choosing between incompatible user-visible behaviors;
- integration must expand scope, introduce a destructive or migration effect,
  or omit material source behavior;
- acceptance has several plausible meanings;
- required evidence depends on unavailable user-controlled state.

Do not ask for an ordinary textual conflict, locally derivable context, a stale
tracking ref with a clear live source, or a policy-compliant syntax adaptation.
When authority for a later side effect is absent, finish the last safe local
boundary and report that pending effect instead of interrupting earlier work.

## Publish, verify, then retire

Follow repository policy for any authorized publication. Refresh target and
source refs, stop on concurrent movement, freeze the exact integration tip,
inspect its outgoing ancestry, and push only the authorized target with lease
protection. Verify the server object before retiring sources.

Delete only authorized source refs, one at a time, after the published target
is verified. Source deletion never authorizes discarding local changes or
recovery history.

Report source/base OIDs, resulting changes and intentional adaptations,
per-candidate and combined evidence, published target if any, retired refs, and
remaining uncertainty.
