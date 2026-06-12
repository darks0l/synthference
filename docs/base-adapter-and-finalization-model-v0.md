# Synthference Base Adapter and Finalization Model v0

## Goal

Define how offchain execution adapters and settlement/finalization agents should bridge Synthference runtime activity into durable Base-anchored outcomes.

This is the missing middle between:
- offchain execution reality
- onchain ownership and settlement commitments

---

## Core idea

Execution happens offchain.
Finalization becomes durable on Base.

Adapters and finalization agents are the bridge.

They should translate:
- route decisions
- runtime outcomes
- proof artifacts
- settlement classification

into a compact, verifiable Base commitment.

---

## Why this layer matters

Without a clear bridge model, Base anchoring becomes messy fast.

Questions show up immediately:
- who is allowed to post final settlement anchors?
- when is a result final enough to anchor?
- what data should be posted directly vs referenced by hash?
- how are disputes or reversals represented?
- how do wallets, agents, and venues know a posted finalization really corresponds to the offchain execution reality?

This document defines a clean bridge posture for v0.

---

## Roles

### 1. Execution adapters
Connect route decisions to actual compute backends.

Examples:
- hosted API adapter
- decentralized node-network adapter
- local runtime adapter
- enterprise gateway adapter

### 2. Proof normalizers
Transform provider-specific logs and usage data into normalized receipt/proof manifests.

### 3. Settlement classifiers
Apply right + request + route + proof logic to determine `full`, `fallback`, `partial`, `failed`, `expired`, or `cancelled`.

### 4. Finalization agents / relayers
Post the canonical settlement anchor to Base after finality conditions are met.

### 5. Indexers
Read Base anchors plus offchain manifests and serve builders a usable lifecycle view.

---

## Recommended v0 bridge flow

```text
request accepted
  -> route locked
  -> execution adapter runs
  -> adapter emits raw execution facts
  -> proof normalizer builds receipt/proof manifest
  -> settlement classifier determines outcome
  -> finalization agent waits for finality condition
  -> settlement anchor posted to Base
  -> indexer exposes durable state
```

---

## Adapter responsibilities

Execution adapters should:
- receive a concrete route and execution policy
- enforce provider/runtime-specific execution rules
- capture request/response references
- capture metering/usage data
- capture fallback or deviation facts
- emit normalized execution inputs for receipt creation

### Important constraint
Adapters should not directly decide economics.
They produce execution facts.
Settlement logic classifies those facts.

---

## Proof manifest posture

A Base anchor should usually not include full raw proof data.
Instead, the system should build a **proof manifest** offchain.

### Manifest may include
- route lock reference
- adapter id
- provider/supplier id
- execution log hash
- output reference hash
- metering reference hash
- fallback reason if any
- timing references
- receipt hash

### Onchain posture
Base stores:
- manifest hash
- receipt hash
- settlement hash
- optional URI or indexer reference

---

## Finalization conditions

A finalization agent should not post immediately just because execution ended.
It should wait until the result is final enough under policy.

### Example finalization conditions
- required proofs present
- settlement classification complete
- any recovery window for missing proof has passed
- dispute-precheck complete
- optional issuer/router/venue confirmation thresholds reached

### v0 recommendation
Default to anchoring after **classification + proof sufficiency**, and use explicit later onchain events if a dispute opens or reversal occurs.

---

## What gets posted to Base

A settlement anchor should minimally include:
- right/package refs
- request or settlement id
- classification enum
- settlement hash
- receipt hash
- proof manifest hash
- finalization status

Optional:
- dispute window end timestamp
- delegate lineage ref
- batch root ref if multiple settlements are posted together

---

## Single-settlement vs batched anchors

### Single-settlement anchors
Best for:
- simplicity
- early implementation
- high-value or low-volume flows

### Batched anchors
Best for:
- lower gas cost per settlement
- higher throughput systems
- routine low-value execution flows

### Recommendation
Start with single settlement anchors or very simple batches.
Do not overcomplicate the first bridge layer.

---

## Authority to finalize

There are several possible models.

### Model 1: protocol relayer
A trusted protocol relayer posts finalization.

### Model 2: issuer-authorized relayer
Issuer or coordinator authorizes one or more settlement relayers.

### Model 3: proof-submitter market
Any actor can submit, as long as the commitment format is valid and challengeable.

### v0 recommendation
Start with protocol or issuer-authorized relayers.
Move toward broader submitter models only once the dispute and verification surface is mature.

---

## Disputes and reversals

Finalization on Base should not assume perfect infallibility.

### Minimum support
The bridge model should support:
- disputed status
- reversed settlement event
- corrected settlement re-anchor

### Good v0 posture
1. post an initial anchor
2. allow disputes through a known path
3. if dispute succeeds, post a reversal/correction anchor

This keeps Base as the durable truth surface even when offchain mistakes happen.

---

## Adapter identity and trust

Not every adapter should be treated as equally trustworthy.

Useful adapter metadata:
- adapter id
- adapter type
- operator
- supported workload classes
- trust profile
- provider coverage
- version

This can live in registry/indexer surfaces and optionally connect to onchain issuer/relayer roles if needed.

---

## Interaction with delegation

If a delegated actor triggers execution, the bridge should preserve:
- source right/package ref
- delegation id or delegation manifest ref
- delegated scope actually consumed
- delegator/delegate lineage when relevant to settlement

This matters for both auditability and secondary-market correctness.

---

## Interaction with packages

If a package is the user-facing control surface, the bridge still needs to identify:
- which underlying right(s) actually funded execution
- which package or tranche selection rule was applied
- whether execution consumed one or multiple components

The chain anchor can stay compact, but the manifest should preserve this lineage.

---

## Suggested v0 data flow

### Offchain objects
- route object
- execution policy object
- receipt object
- proof manifest
- settlement object

### Onchain anchor
- right/package ref
- settlement classification
- hashes of the above objects as needed
- finalization metadata

### Indexer/composer view
- reconstructs the readable lifecycle from both sides

---

## Failure cases

### Missing proof
Do not finalize until recovery policy is satisfied or failure is classified appropriately.

### Route expired before valid completion
Anchor as `expired` if the settlement engine classifies it so.

### Adapter crash with partial facts
Preserve whatever proof exists, classify according to policy, and only then anchor.

### Wrong anchor posted
Use dispute/reversal path; do not silently mutate history.

---

## Open questions

- should settlement anchors point to one combined manifest hash or multiple dedicated hashes?
- when should batch roots become mandatory?
- should adapter identity be onchain-attested or purely offchain-indexed at first?
- how much of dispute handling should Base contracts verify directly?
- should some premium flows require multi-party signatures before anchoring?

---

## v0 takeaway

The adapter/finalization bridge is what makes the hybrid architecture real.

Offchain systems execute and interpret the work.
Base receives compact, durable commitments once outcomes are final enough to matter.

That split preserves speed and flexibility while still giving Synthference a canonical settlement rail.
