# Synthference Proof Requirements v0

## Goal

Define the minimum proof set needed for routing outcomes, receipt classification, and dispute handling to remain objective enough for settlement.

This document focuses on **minimum viable proof requirements**, not perfect verification.

---

## Why this matters

A receipt that says "success" is not enough by itself.

The protocol needs to know:
- what was requested
- what route was selected
- what was actually attempted
- what was actually delivered
- which fallback path was used, if any
- whether the evidence meets the right's policy requirements

Without proof minimums, settlement becomes subjective and disputes become social arguments.

---

## Design principles

1. **Minimum viable evidence** - enough proof to classify outcomes consistently
2. **Normalized** - proof references should not depend on one provider's quirks
3. **Layered** - not every request needs the same proof strength
4. **Challengeable** - proof objects should support dispute review
5. **Portable** - proof requirements should work across centralized, local, and decentralized supply

---

## Proof layers

Synthference proof should be thought of in layers.

### Layer 1: Invocation proof
Shows that a specific request was actually submitted under a specific right and routing decision.

### Layer 2: Execution proof
Shows that a supplier or execution environment actually attempted or completed work.

### Layer 3: Delivery proof
Shows that the declared result was actually produced or made available.

### Layer 4: Metering proof
Shows how much resource was actually consumed or delivered.

### Layer 5: Fallback / exception proof
Shows whether degraded fulfillment, deferral, or failure happened inside policy.

---

## Minimum proof set by outcome

### For `full`
Minimum proof set:
- request reference
- selected route reference
- execution completion record
- metering record
- delivery artifact or delivery reference

### For `fallback`
Minimum proof set:
- all `full` proofs
- fallback reason code
- fallback policy reference
- proof that fallback remained inside allowed bounds

### For `partial`
Minimum proof set:
- execution record
- metering record for delivered subset
- proof of incomplete or truncated completion
- settlement calculation basis for the recognized partial amount

### For `failed`
Minimum proof set:
- invocation proof
- execution attempt or failure record
- failure reason code
- proof showing why no valid delivery was recognized

### For `expired`
Minimum proof set:
- right window reference
- request timing reference
- evidence that valid completion did not occur within the allowed window

### For `cancelled`
Minimum proof set:
- authorized cancellation event
- timing relative to route lock / execution start
- any non-recoverable consumed amount if applicable

---

## Normalized proof object

A receipt or settlement input should reference proof artifacts using a normalized structure.

```json
{
  "proofs": [
    {
      "proofType": "execution-log",
      "proofRef": "proof_exec_01",
      "producer": "supplier:node-17",
      "time": "2026-06-12T00:00:00Z",
      "integrity": {
        "hash": "sha256:...",
        "signatureRef": "sig_abc"
      }
    }
  ]
}
```

---

## Recommended proof types

### Invocation / routing
- `request-envelope-hash`
- `route-selection-record`
- `route-lock-record`

### Execution
- `execution-log`
- `completion-record`
- `failure-record`
- `deferred-run-record`

### Metering
- `usage-meter`
- `latency-measurement`
- `delivered-unit-count`

### Delivery
- `artifact-hash`
- `output-reference`
- `availability-reference`

### Policy / fallback
- `fallback-reason`
- `policy-evaluation-record`
- `constraint-check-record`

### Dispute support
- `attestation`
- `challenge-record`
- `review-decision-record`

---

## Who can produce proofs

Proof producers may include:
- issuer
n- router / coordinator
- supplier / provider
- local execution gateway
- independent metering component
- dispute reviewer / adjudication module

### Important rule
The protocol should not assume every proof producer is equally trusted.

That is why proof strength should depend on:
- proof type
- integrity method
- producer role
- policy requirements of the right

---

## Integrity expectations

Proofs should ideally support at least one integrity mechanism:
- hash binding
- signature binding
- append-only event reference
- coordinator-issued signed receipt
- trusted local gateway attestation

v0 does not require a single universal mechanism, but it should require that proof objects are referenceable and tamper-evident enough for later review.

---

## Proof sufficiency profiles

Different rights may require different proof minima.

### Example profiles
- `basic` - enough for normal low-risk background or economy usage
- `standard` - suitable for normal production routing and partial/fallback settlement
- `strict` - suitable for premium, privacy-sensitive, or dispute-heavy usage

### Example

```json
{
  "proofProfile": "standard",
  "requiredProofTypes": [
    "request-envelope-hash",
    "route-selection-record",
    "execution-log",
    "usage-meter",
    "output-reference"
  ]
}
```

---

## Dispute handling implications

Proof requirements matter most when things go wrong.

A dispute process should be able to ask:
- was the selected route consistent with policy?
- did execution actually start?
- did it complete?
- was a fallback path used?
- was the fallback allowed?
- what amount should count as delivered?

If the proof set cannot answer those questions, the settlement engine should classify the outcome conservatively.

---

## Conservative default rule

When proof is incomplete:
- do not classify ambiguous outcomes as `full`
- prefer `pending_proof`, `partial`, or `failed` depending on policy and recoverability
- avoid optimistic interpretation when settlement consequences differ materially

---

## Suggested schema hooks

The right's settlement policy should be able to declare:
- `proofProfile`
- `requiredProofTypes`
- `minimumIntegrityModes`
- `disputeWindowSeconds`

The execution receipt should then reference the actual delivered proof set.

---

## Open questions

- should proof profiles live directly in the right schema or in external policy templates?
- when is a router-signed record enough versus supplier-signed proof?
- how should local execution proofs be normalized across different runtimes?
- should proof minimums vary by workload class or by quality / privacy tier?
- which disputes can be resolved automatically versus requiring human or governance review?

---

## v0 takeaway

Synthference needs more than success flags.

It needs a minimum proof language that ties request, route, execution, delivery, and fallback behavior together tightly enough for settlement to remain mechanical instead of hand-wavy.
