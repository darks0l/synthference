# Synthference Capacity Assurance Model v0

## Goal

Define how a Synthference issuer can back issued rights with enough observable capacity assurance to avoid vague promises and uncontrolled over-issuance.

This document intentionally avoids assuming one financial structure. The focus is narrower: what evidence and controls should exist before a right is issued and while it remains active.

---

## Why this matters

A right is only useful if the system can explain, in bounded terms, why it is reasonable to issue it.

Without a capacity assurance model, Synthference degrades into:
- abstract promises without supply discipline
- routing policy with no issuance guardrails
- settlement logic that arrives too late to fix bad issuance

The protocol therefore needs a way to answer a simple question:

**What capacity basis justifies this right existing at all?**

---

## Design principles

1. **Bounded issuance** - rights should be tied to explicit capacity assumptions
2. **Observable basis** - the assurance basis should be inspectable, not implied
3. **Policy-aware** - different supply sources can justify issuance differently
4. **Refreshable** - assurance should be re-evaluated across time windows
5. **Failure-conscious** - the model should assume supply can drift or degrade

---

## Core idea

A right should carry or reference a **capacity assurance basis** describing the source of confidence behind issuance.

That basis does not need to be identical for all issuers.

Examples:
- posted supplier inventory
- reserved provider capacity
- measured historical availability with conservative haircut
- dedicated local cluster allocation
- coordinator-managed reserved pool
- explicit overflow tolerance policy

The important thing is that the assurance basis is:
- named
- constrained
- reviewable
- linked to issuance limits

---

## Assurance object

A right issuer should maintain or reference a capacity assurance object.

### Minimal shape

```json
{
  "assuranceId": "assure_text_interactive_us_01",
  "assuranceMode": "reserved-capacity",
  "resourceClass": "text.generation",
  "window": {
    "start": "2026-06-12T00:00:00Z",
    "end": "2026-06-19T00:00:00Z"
  },
  "capacityBasis": {
    "unit": "tokens",
    "grossAmount": 10000000,
    "usableAmount": 7500000,
    "haircutBps": 2500
  },
  "sources": [
    {
      "sourceType": "supplier-registry-slice",
      "sourceRef": "sup_text_us_interactive"
    }
  ],
  "refreshPolicy": {
    "mode": "epoch",
    "intervalSeconds": 3600
  }
}
```

---

## Assurance modes

### 1. `reserved-capacity`
Rights are backed by explicitly reserved supply.

Good for:
- dedicated provider allotments
- reserved cluster slices
- coordinator-held capacity windows

### 2. `inventory-posted`
Rights are backed by supplier-posted availability that is accepted into the registry under protocol policy.

Good for:
- decentralized or federated supply
- coordinator-mediated supply listings

### 3. `historical-availability`
Rights are issued conservatively against measured historical capacity rather than hard reservation.

Good for:
- recurring local/operator supply
- predictable low-volatility workloads

This mode should use larger safety haircuts.

### 4. `local-allocation`
Rights are backed by dedicated local or private-cluster allocation.

Good for:
- enterprise internal routing
- single-operator environments
- privacy-sensitive execution pools

### 5. `hybrid`
Rights are backed by a defined combination of the above.

Good for:
- reserved baseline + overflow inventory
- private-first with hosted fallback

---

## Capacity basis fields

### `grossAmount`
Total raw supply observed or reserved before safety reduction.

### `haircutBps`
Conservative reduction applied to reflect uncertainty, supplier drift, contention, measurement noise, or policy buffers.

### `usableAmount`
The amount that may actually justify issuance after haircut and policy guards.

### Rule
Issued active rights for the same capacity slice should not exceed usable capacity unless the protocol explicitly permits controlled oversubscription for that slice.

---

## Controlled oversubscription

Some environments may permit limited oversubscription.

If so, it should be explicit and bounded.

### Example fields

```json
{
  "oversubscriptionPolicy": {
    "allowed": true,
    "maxOverbookBps": 500,
    "justification": "historical non-concurrent utilization",
    "degradationPlan": "defer-within-window"
  }
}
```

### Notes
- oversubscription should never be silent
- the fallback/degradation plan should be known in advance
- rights relying on oversubscription should likely disclose stricter fallback or deferral behavior

---

## Issuance controls

Before issuing a new right, the issuer should check:

1. matching assurance basis exists
2. requested resource/service/window fit that basis
3. new issuance stays within usable capacity policy
4. fallback and settlement policy remain compatible with assurance mode
5. refresh state is current enough for the issuance window

If those checks fail, the issuer should:
- reject issuance
- reduce size
- narrow the window
- lower priority / latency guarantees
- require a different assurance mode

---

## Relationship to supplier registry

The supplier registry describes what supply can do.

The capacity assurance model describes why issuance against that supply is justified.

Those are related, but not the same thing.

A supplier may advertise a capability, but the issuer still needs a policy for how much of that capability can safely back rights during a given window.

---

## Relationship to settlement

Capacity assurance does not replace settlement.

Instead:
- assurance governs whether a right should exist
- routing governs how it is consumed
- settlement governs what actually happened

A protocol that skips assurance and hopes settlement will clean things up later is already too late.

---

## Assurance drift

Capacity can change after issuance.

The model should therefore support drift handling.

### Example responses to drift
- pause new issuance against a slice
- reduce future issuance size
- move rights into stricter fallback posture
- limit high-priority consumption first
- mark an assurance slice degraded for routing purposes

### Important note
Drift responses should be policy-defined, not improvised after failure.

---

## Recommended v0 issuer metadata

A right should at minimum reference:
- `assuranceMode`
- `assuranceRef` or embedded assurance slice id
- issuance window
- capacity unit
- usable issuance basis

This gives routers, auditors, and holders more than just a promise.

---

## Open questions

- when should assurance objects be embedded versus referenced?
- should assurance refresh events be first-class registry events?
- how should multi-supplier hybrid assurance slices be normalized?
- should some assurance modes be disallowed for premium or realtime rights?
- how should assurance degradation propagate to already-issued rights?

---

## v0 takeaway

Synthference should not issue rights against vibes.

Each right needs a named capacity assurance basis with explicit usable capacity, a conservative policy buffer, and a clear connection between supply reality and issuance boundaries.
