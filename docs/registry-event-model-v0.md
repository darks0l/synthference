# Synthference Registry Event Model v0

## Goal

Define the canonical event model for recording right, request, route, receipt, settlement, amendment, and finalization activity inside a Synthference registry.

The registry should not just store current state.
It should preserve a structured event history that explains how the state became what it is.

---

## Why this matters

A static registry snapshot is not enough.

Holders, routers, issuers, suppliers, and settlement engines need to answer questions like:
- when was this right issued?
- what changed after issuance?
- was the right amended or partially consumed?
- which route was selected?
- when did settlement become final?
- was there a dispute or reversal?

Without a clear event model, systems end up reconstructing history from ad hoc logs or hidden database state.
That makes routing, settlement, audits, and disputes much harder than they need to be.

---

## Design principles

1. **Events explain state** - registry state should be derivable from ordered events
2. **Amendments are explicit** - changes after issuance must not be silent overwrites
3. **Finalization is observable** - event history must show when a state became economically or operationally final
4. **Composable across deployments** - event types should work for centralized, federated, and private deployments
5. **Receipt and settlement aware** - registry events should line up cleanly with execution and settlement surfaces

---

## Core idea

The registry should model major lifecycle changes as append-only events.

That does not force one storage engine or consensus model.
It just means that every meaningful transition should have a normalized event representation.

A current registry snapshot may still be materialized for convenience, but the event stream is the deeper truth.

---

## Event scopes

Registry events may attach to different object scopes.

### 1. Right-scoped
Events about a right's creation, amendment, status, balance, expiry, or finalization.

### 2. Request-scoped
Events about invocation, route selection, execution progress, and request-level settlement.

### 3. Route-scoped
Events about route quote creation, lock, expiry, replacement, or release.

### 4. Settlement-scoped
Events about classification, dispute, reversal, and finalization.

### 5. Registry-scoped
Events about catalog or governance changes affecting registry interpretation.

---

## Minimal event envelope

```json
{
  "eventId": "evt_01",
  "eventType": "right.issued",
  "objectType": "right",
  "objectId": "sr_01",
  "registryId": "reg_01",
  "occurredAt": "2026-06-12T00:00:00Z",
  "actor": {
    "actorType": "issuer",
    "actorId": "mesh_alpha"
  },
  "sequence": 182,
  "payload": {},
  "refs": {
    "rightId": "sr_01",
    "requestId": null,
    "routeRef": null,
    "receiptRef": null,
    "settlementRef": null,
    "priorEventId": null
  },
  "integrity": {
    "hash": "sha256:...",
    "signatureRef": "sig_01"
  }
}
```

---

## Required envelope fields

### `eventId`
Unique event identifier.

### `eventType`
Normalized lifecycle event name.

### `objectType`
Primary object affected, such as `right`, `request`, `route`, `receipt`, `settlement`, or `registry`.

### `objectId`
Identifier of the primary object affected.

### `occurredAt`
Canonical event timestamp.

### `actor`
Who or what caused the event.
Examples:
- issuer
- holder
- router
- settlement-engine
- supplier
- governance process

### `sequence`
A monotonic ordering field inside the registry or shard.

### `payload`
Event-specific structured data.

### `refs`
Pointers to other relevant objects or prior events.

---

## Core right lifecycle events

### `right.issued`
Created when a new right enters the registry.

Payload examples:
- right version
- issuer metadata
- assurance reference
- initial active amount
- initial lifecycle state

### `right.activated`
Used when an issued right becomes usable, if issuance and activation are distinct.

### `right.amended`
Records a structured amendment to a right without pretending the original right never existed.

Payload examples:
- amended fields
- amendment reason
- effective time
- amendment class

### `right.balance_changed`
Records a balance change tied to settlement, release, reissue, burn, or correction.

### `right.partially_consumed`
Optional explicit event for readability when a right is partially used.
Could also be represented through `right.balance_changed` plus settlement refs.

### `right.fully_consumed`
Marks depletion of usable balance.

### `right.expired`
Marks that the right's usable window has elapsed.

### `right.finalized`
Marks that no further ordinary lifecycle mutation is expected.
This is different from simple expiry or depletion.

---

## Core request and route events

### `request.submitted`
A holder or agent invokes a right.

### `request.accepted`
The request is accepted into routing/execution flow.

### `route.quoted`
A router produces one or more candidate route options.

### `route.locked`
A selected route is reserved or locked for execution.

### `route.replaced`
An earlier route is superseded.

### `route.expired`
A route lock expires before valid completion.

### `route.released`
Reserved route capacity is released.

### `request.cancelled`
An authorized actor cancels a request.

---

## Core execution and receipt events

### `execution.started`
Execution begins under a specific route and policy envelope.

### `execution.progressed`
Optional event for deferred or long-running flows.

### `execution.completed`
Execution completed and produced a receipt candidate.

### `receipt.recorded`
A normalized receipt is stored or referenced in the registry.

### `receipt.invalidated`
A receipt is rejected or superseded.

---

## Core settlement events

### `settlement.classified`
Settlement engine classifies the request as full, fallback, partial, failed, expired, or cancelled.

### `settlement.pending_proof`
Classification is blocked pending proof recovery.

### `settlement.pending_dispute_window`
The provisional economic result exists but is not yet final.

### `settlement.dispute_opened`
A dispute is formally opened.

### `settlement.dispute_closed`
A dispute is resolved.

### `settlement.reversed`
A prior settlement result is reversed.

### `settlement.finalized`
The settlement result becomes final for normal protocol purposes.

---

## Amendment model

Amendments should not silently rewrite the meaning of an existing right.

### Amendment classes
Useful v0 amendment categories:
- `metadata-only`
- `window-adjustment`
- `limit-adjustment`
- `fallback-adjustment`
- `holder-reassignment`
- `issuer-correction`
- `administrative-freeze`

### Amendment rules
A registry should define which fields are:
- immutable after issuance
- amendable before activation only
- amendable while active with notice
- never amendable without replacement/reissuance

### Recommended posture
For v0, treat the following as hard to amend once active:
- core resource class
- core privacy class
- settlement proof baseline
- issuer identity

If those need to change materially, replacement plus explicit linkage is cleaner than mutation.

---

## Replacement vs amendment

These should not be collapsed.

### Amendment
Same right identity continues, with bounded changes.

### Replacement
A new right is created and linked to the old one.

Useful replacement event patterns:
- `right.replaced`
- `right.reissued_from`
- `right.migrated`

Replacement is often cleaner when:
- assurance basis changes materially
- core policy shape changes
- active supply lane changes
- a dispute or corrective action requires a fresh object

---

## Finalization model

Finalization should be explicit because many protocol questions depend on it.

### Examples of finalization
- settlement dispute window closes
- right is fully consumed and no reissue path remains
- right expires with no remaining amendment/recovery path
- registry migration closes the old object and points to the new one

### Why this matters
A right can be inactive without being truly final.
For example:
- a partially consumed right may still be amendable
- a classified settlement may still be disputeable
- a depleted right may still have refund or reversal exposure

---

## Event ordering

The registry should define a clear event ordering rule.

### Good enough v0 options
- single monotonic sequence inside one registry
- per-object version + timestamp + integrity hash
- shard-local sequence with cross-ref integrity for larger systems

The exact implementation can vary.
The important thing is that conflicting interpretations of order should be minimized.

---

## Derived views

The event stream should support derived views like:
- current right state
- current usable balance
- current request state
- current route status
- settlement finality state
- full lifecycle timeline for one object

Materialized views are fine.
They just should not be the only source of meaning.

---

## Example lifecycle slice

```text
right.issued
right.activated
request.submitted
route.quoted
route.locked
execution.started
execution.completed
receipt.recorded
settlement.classified
right.balance_changed
settlement.pending_dispute_window
settlement.finalized
right.finalized
```

This makes the object's history inspectable without needing private database knowledge.

---

## Relationship to onchain and offchain deployments

This model works whether the registry is:
- fully offchain
- partially onchain with offchain detail logs
- mirrored across multiple systems

Not every event must be onchain.
But if one system stores the canonical event history, the protocol should still expose normalized event semantics.

---

## Open questions

- should some event types be mandatory while others remain optional annotations?
- when should `right.partially_consumed` exist separately from `right.balance_changed`?
- should amendments require holder acknowledgment for some classes?
- how should federated registries merge event ordering across shards or domains?
- should finalization always require a dedicated event, even when implied by depletion or expiry?

---

## v0 takeaway

The registry should be more than a table of current balances.

Synthference needs an event model that makes issuance, amendment, execution, settlement, dispute, and finalization legible over time.
That is what turns the registry into real protocol memory instead of a mutable black box.
