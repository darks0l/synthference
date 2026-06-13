<p align="center">
  <img src="./assets/synthference-banner.png" alt="Synthference banner" width="900" />
</p>

<h3 align="center">Built by DARKSOL</h3>

<h1 align="center">Synthference</h1>

<p align="center">
  <img alt="Status" src="https://img.shields.io/badge/status-concept%20spec-ffb347?style=for-the-badge" />
  <img alt="Category" src="https://img.shields.io/badge/category-compute%20rights-1f2937?style=for-the-badge" />
  <img alt="Focus" src="https://img.shields.io/badge/focus-routing%20%2B%20settlement-111827?style=for-the-badge" />
  <img alt="Spec" src="https://img.shields.io/badge/spec-v0-7c3aed?style=for-the-badge" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-gold?style=for-the-badge" />
</p>

**Synthetic inference rights** - a general primitive for representing, routing, and settling future compute access.

## What it is

Synthference is a concept and protocol direction for turning inference access into **programmable rights over future compute** instead of raw prepaid credits, provider-locked balances, or debt-backed service guarantees.

A Synthference position can express:
- compute class
- quality band
- latency band
- time window
- max deliverable units
- fallback rules
- settlement outcomes

## Why

Today, compute access is usually packaged as:
- API keys
- provider credits
- fixed subscriptions
- marketplace resale of opaque balances

Those models are brittle, provider-specific, and hard to route across heterogeneous supply.

Synthference reframes compute access as a **bounded, time-scoped claim** on future inference capacity that can be:
- acquired
- routed
- rebalanced
- partially fulfilled
- gracefully degraded
- settled by outcome

## Core idea

Instead of promising infinite service and introducing hidden insolvency or hard cutoffs, Synthference models compute access as **bounded synthetic rights**.

That means:
- no assumption of perfect real-time fulfillment
- explicit fallback behavior under stress
- portable rights across providers and networks
- cleaner secondary markets for future compute
- better agent-native control over inference policy

## Primitive shape

A right may define:
- **capacity type** - text, image, video, embeddings, agent runtime, GPU-seconds
- **priority** - premium, standard, background
- **latency** - realtime, interactive, batch
- **scope** - provider set, model family, privacy or jurisdiction constraints
- **window** - start, expiry, or rolling epoch
- **units** - requests, tokens, jobs, frames, seconds
- **fallbacks** - acceptable substitutions if ideal execution is unavailable
- **settlement** - full, fallback, partial, expired, failed

## Early framing

Synthference is intended as a **general primitive**, not a single-network product.

It should be usable across:
- centralized inference APIs
- decentralized node networks
- local/private clusters
- enterprise compute pools
- hybrid agentic routing systems

## Initial thesis

The right abstraction for inference may not be:
- a token for API usage
- a prepaid provider balance
- or a debt-like service promise

It may be a **synthetic right to future compute**, with programmable routing and bounded settlement.

## Spec

- [Schema v0](./docs/schema-v0.md)
- [Request Envelope v0](./docs/request-envelope-v0.md)
- [Execution Receipt v0](./docs/execution-receipt-v0.md)
- [Settlement State Machine v0](./docs/settlement-state-machine-v0.md)
- [System Modules v0](./docs/system-modules-v0.md)
- [Supplier Capability Taxonomy v0](./docs/supplier-capability-taxonomy-v0.md)
- [Capacity Assurance Model v0](./docs/capacity-assurance-model-v0.md)
- [Proof Requirements v0](./docs/proof-requirements-v0.md)
- [Worked Examples v0](./docs/worked-examples-v0.md)
- [Agent Execution Policy v0](./docs/agent-execution-policy-v0.md)
- [Issuance Paths v0](./docs/issuance-paths-v0.md)
- [Registry Event Model v0](./docs/registry-event-model-v0.md)
- [Right Packaging and Secondary Market Semantics v0](./docs/right-packaging-and-secondary-markets-v0.md)
- [Lifecycle Diagrams and Flow Guidance v0](./docs/lifecycle-diagrams-and-flow-guidance-v0.md)
- [Synthference on Base Architecture v0](./docs/synthference-on-base-architecture-v0.md)
- [Base Contract Surface v0](./docs/base-contract-surface-v0.md)
- [Base Adapter and Finalization Model v0](./docs/base-adapter-and-finalization-model-v0.md)
- [Onchain Right Representation v0](./docs/onchain-right-representation-v0.md)
- [RightRegistry Object Model v0](./docs/right-registry-object-model-v0.md)
- [RightRegistry Solidity Surface v0](./docs/right-registry-solidity-surface-v0.md)
- [RightRegistry contract draft](./contracts/RightRegistry.sol)

## Next

- tighten schema examples and add reference JSON fixtures
- decide whether package objects belong in the base schema or stay as registry extensions
- extend the current Hardhat validation lane with lifecycle, split, freeze, finalize, and transfer-gating tests
- prototype one concrete Base implementation slice (`RightRegistry` + `SettlementAnchor`)

Built with teeth. 🌑
