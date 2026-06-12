# Synthference

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
- [System Modules v0](./docs/system-modules-v0.md)

## Next

- refine the v0 schema into an implementable envelope
- define settlement proofs and dispute boundaries
- map router policy to agent-native execution
- model rebalance and degradation paths under stress
- compare issuance paths across centralized and decentralized supply

Built with teeth. (moon)
