# Synthference on Base Architecture v0

## Goal

Define a practical architecture for running Synthference with **Base** as the canonical ownership, registry, delegation, and settlement-anchor layer, while keeping routing and execution offchain.

This is the recommended path if the system wants onchain portability and transfer rails without forcing the entire compute runtime onto a chain.

---

## Core recommendation

Use **Base as the anchor layer, not the engine room**.

That means:
- onchain for durable rights, ownership, delegation, package lineage, and finalized settlement anchors
- offchain for routing, live availability, execution policy, proof capture, and provider/runtime interaction

This gives the system a strong canonical state surface without dragging fast operational state into expensive or privacy-hostile environments.

---

## Why Base fits

Base is a good anchor layer for this design because it offers:
- low enough cost for frequent state anchoring compared to L1
- standard EVM tooling and wallet compatibility
- strong composability for transfer, approval, delegation, and marketplace hooks
- cleaner path for later financial or coordination layers if the protocol grows

The goal is not "put all compute onchain."
The goal is "put the durable rights layer somewhere portable and inspectable."

---

## Architecture split

### Onchain responsibilities
Base should handle:
- right identifiers and canonical ownership
- issuer registration / attestation references
- transfer and approval mechanics
- delegation approvals and scoped authorization surfaces
- package lineage or package registry references
- finalized settlement commitments
- dispute/finalization state where needed for durable public truth

### Offchain responsibilities
The offchain control plane should handle:
- supplier discovery and live inventory
- routing and route selection
- route locks and ephemeral reservations
- execution policy enforcement
- provider adapters / node adapters / local runtime adapters
- proof collection and normalization
- fast metering and runtime logs
- pre-finalization reconciliation

---

## System layers

### 1. Base contract layer
Canonical smart contracts for rights, packages, delegation, and settlement anchoring.

### 2. Registry / indexer layer
An offchain indexer that follows Base events plus protocol event streams to serve builders and agents efficiently.

### 3. Routing and execution layer
Coordinator and/or agent runtime that selects routes, enforces policy, and orchestrates execution.

### 4. Adapter layer
Provider-specific and network-specific adapters that turn route decisions into real compute execution.

### 5. Finalization / relayer layer
Trusted or semi-trusted relayers, provers, or settlement agents that turn offchain execution outcomes into Base-anchored finalization records.

---

## High-level lifecycle on Base

```text
capacity basis (offchain)
   -> right issuance decision (offchain policy)
   -> right minted / registered on Base
   -> holder owns or receives delegated control
   -> request + routing + execution happen offchain
   -> receipt + proofs normalized offchain
   -> final settlement commitment posted to Base
   -> indexers expose canonical lifecycle view
```

---

## Design principles

1. **Canonical ownership onchain** - rights should have durable public identity
2. **Execution offchain** - keep fast-changing operational state off the chain
3. **Commit, do not stream** - chain should receive important commitments, not every runtime heartbeat
4. **Proof-friendly finalization** - settlement anchors should point to verifiable offchain facts
5. **Upgradeable control plane, stable anchor plane** - routing/adapters can evolve faster than ownership semantics

---

## What should go onchain first

The first Base version should likely include:
- `RightRegistry`
- issuer attestation references
- right mint/transfer/approval flows
- delegation authorization
- package references or package registry hooks
- settlement anchor/finalization events

This is enough to make the rights layer portable and market-capable without prematurely locking in the full runtime design.

---

## What should stay offchain first

Do **not** put these onchain in the first pass:
- live supplier availability
- route quote generation
- route lock churn
- provider-specific execution traces
- raw output payloads
- large proof artifacts
- rapid metering updates
- ephemeral retries/fallback attempts

Those belong in the control plane and proof layer.

---

## Onchain object posture

### Rights
Should be first-class onchain objects or token-like records with explicit protocol metadata references.

### Delegations
Should be onchain if the protocol wants wallets, agents, or venues to reason about authority cleanly.

### Packages
Could be first-class onchain or referenced as registry-managed package objects depending on complexity and gas budget.

### Settlement records
Should be anchored onchain as finalized commitments, not necessarily as full receipts.

---

## State commitment model

A useful Base posture is:
- **full detail offchain**
- **canonical hash/commitment onchain**

Examples:
- right metadata hash
- package composition hash
- settlement bundle hash
- dispute-resolution outcome hash
- proof manifest hash

This keeps the onchain layer compact while preserving auditability.

---

## Recommended control-plane behavior

### Before issuance
- evaluate assurance basis offchain
- derive right terms
- mint/register right on Base with metadata reference

### Before execution
- verify holder or delegate authority against Base state
- resolve current control and allowances
- build route and execution policy offchain

### After execution
- produce normalized receipt and settlement classification offchain
- post final settlement anchor to Base once finality conditions are satisfied

---

## Why not pure onchain execution semantics

A fully onchain execution-heavy design would create problems fast:
- supplier inventory changes too quickly
- route locks are too ephemeral
- privacy-sensitive workloads should not expose their details publicly
- proof artifacts can be too large and provider-specific
- fallback behavior is too operationally noisy
- gas economics would pressure the protocol toward oversimplification

So the chain should record durable truth, not operational turbulence.

---

## Role of Base in secondary markets

Base becomes especially valuable once rights move between actors.

It can serve as the canonical rail for:
- ownership transfer
- package transfer
- delegation approval
- venue integration
- settlement visibility
- escrow or marketplace hooks later

This is where an anchor-chain approach starts compounding in value.

---

## Indexer model

A good implementation should expose an indexer that combines:
- Base contract events
- registry events
- settlement anchors
- offchain object manifests

The chain gives canonical ownership/finality.
The indexer gives usability.

---

## Suggested v0 deployment phases

### Phase 1
Offchain-only prototype of rights, routing, execution, and settlement semantics.

### Phase 2
Base `RightRegistry` + ownership + delegation + settlement anchor rollout.

### Phase 3
Package lineage / transfer support on Base.

### Phase 4
Optional venue integration, escrow hooks, or secondary-transfer rails.

### Phase 5
Stronger dispute or proof-verification extensions if the protocol needs them.

---

## Open questions

- should rights be represented as ERC-721-like unique positions, ERC-1155-like classes, or custom records?
- how much package composition should be explicit onchain versus hash-referenced?
- should settlement anchors be per-request or batched?
- when should disputes live fully onchain versus onchain-finalized from offchain arbitration?
- should issuer attestations be simple references or actively verified contract-side?

---

## v0 takeaway

If Synthference wants Base, the right move is not to drag the full runtime onto the chain.

The right move is to use Base as the **durable rights and settlement rail**, while the offchain control plane continues to handle routing, execution, proofs, and fast operational state.
