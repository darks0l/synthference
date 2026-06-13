# Synthference Onchain Right Representation v0

## Goal

Decide how a Synthference right should be represented on Base in the first practical onchain version.

This document compares three candidate postures:
- **ERC-721-like unique positions**
- **ERC-1155-like semi-fungible classes**
- **custom registry records**

It then recommends the best v0 default.

---

## What the representation has to support

A Synthference right is not just "some balance."
It may vary by:
- workload class
- quantity and unit model
- usable window
- latency / privacy / jurisdiction constraints
- fallback permissions
- partial-fill posture
- settlement history
- delegation lineage
- package membership
- amendment or split lineage

That means the representation has to preserve **identity, policy shape, and lifecycle**, not only ownership.

---

## Evaluation criteria

The right v0 choice should optimize for:

1. **policy expressiveness**
2. **clear ownership and transfer semantics**
3. **clean delegation and package composition**
4. **partial-consumption / lifecycle tracking**
5. **secondary-market friendliness**
6. **implementation simplicity**
7. **future room for standardization or fungible wrappers**

---

## Option 1: ERC-721-like unique positions

### Shape
Each right is represented as a unique position with its own ID and metadata reference.

### Why it fits
This aligns naturally with the current Synthference posture:
- rights are policy-rich
- rights can differ in time window and limits
- settlement lineage matters
- amendments, splits, and packaging matter
- two rights with the same rough category may still not be economically identical

### Strengths
- **strong identity** for each right
- **simple ownership model** for wallets, venues, and agents
- **natural fit for unique policy terms**
- **clean delegation reference point** (`rightId` is the canonical object)
- **clean linkage to settlement anchors**
- **easy lineage modeling** for split / merge / amendment references
- **portable NFT-style transfer rails** for early market experimentation

### Weaknesses
- not naturally fungible
- awkward if the protocol later wants highly liquid pooled classes
- partial-consumption semantics may require explicit protocol state instead of "just lower a balance"
- may create many unique objects if issuance becomes extremely granular

### Best use
- bespoke rights
- policy-rich rights
- time-scoped or issuer-differentiated rights
- early protocol versions where semantics matter more than liquidity efficiency

---

## Option 2: ERC-1155-like semi-fungible classes

### Shape
Rights are grouped into class IDs, and holders own balances of a given class.

### Why it is attractive
If Synthference eventually offers highly standardized inventory classes, ERC-1155-like balances become attractive because they:
- reduce per-position overhead
- make pooled liquidity easier
- support batch transfer patterns well

### Strengths
- **better for standardized classes**
- **more efficient for repeated issuance**
- **natural for pooled inventory buckets**
- **good batch transfer ergonomics**
- **easier path to venue-friendly class trading** for homogeneous rights

### Weaknesses
- requires strong standardization of right terms
- weak fit for rights with bespoke windows, fallback policy, or settlement nuance
- awkward when one balance lot has different amendment or partial-consumption history than another
- can blur important distinctions between superficially similar but economically different rights
- package lineage and settlement lineage become harder to reason about if many units share a class id

### Best use
- later-stage standardized products
- inventory classes with tight normalization
- pooled / trancheable rights after the base semantics are already proven

---

## Option 3: Custom registry records

### Shape
Rights are stored as protocol-specific records in a custom registry without leaning on ERC-721 or ERC-1155 transfer semantics.

### Why it is tempting
A custom registry gives maximum freedom.
The protocol can define exactly the lifecycle, authority, and settlement hooks it wants.

### Strengths
- **maximum protocol control**
- **cleanest fit for custom lifecycle rules**
- **can model controller / delegate / issuer distinctions more explicitly**
- **no need to bend semantics around token standards**

### Weaknesses
- weakest out-of-the-box wallet / venue composability
- requires more custom integration work everywhere
- less legible to external markets and tooling
- increases protocol surface area early
- easier to over-design before real usage teaches the right abstractions

### Best use
- when standard token transfer semantics are actively harmful
- when the protocol has already proven that token-like ownership is the wrong mental model
- when specialized authority/control rules dominate portability concerns

---

## Comparison summary

| Criterion | ERC-721-like | ERC-1155-like | Custom registry |
|---|---|---:|---:|
| unique policy-rich rights | **strong** | weak-medium | **strong** |
| fungible standardized classes | weak | **strong** | medium |
| wallet / venue familiarity | **strong** | **strong** | weak |
| lineage / settlement clarity | **strong** | medium | **strong** |
| partial consumption ergonomics | medium | **strong** | **strong** |
| implementation simplicity for v0 | **strong** | medium | medium-weak |
| long-term flexibility | strong | strong | **strong** |

---

## Recommendation

## Use an **ERC-721-like unique position model for v0**.

That is the cleanest default for the first Base-anchored Synthference rights layer.

### Why this is the right v0 call

Because the protocol has not yet earned the assumption that rights are meaningfully fungible.

Right now, the important truth is:
- policy shape matters
- issuer posture matters
- windows matter
- fallback posture matters
- settlement classification matters
- package and delegation lineage matter

That all points toward **unique positions first**.

An ERC-721-like posture gives:
- canonical identity
- easy ownership reasoning
- clean settlement linkage
- natural package/delegation references
- good portability across Base-native tooling

It also keeps the system honest.
It prevents the design from pretending that heterogeneous rights are interchangeable before the market and protocol semantics prove that they are.

---

## Important nuance

This does **not** mean the full protocol should be forever NFT-shaped.

The better long-term posture is likely:

1. **unique rights first**
2. **packages and composition next**
3. **standardized classes or fungible wrappers later, where justified**

In other words:
- use unique positions for canonical truth
- add ERC-1155-like or pooled abstractions later for proven homogeneous classes
- keep room for custom registry helpers where protocol-specific control is needed

The canonical base object should still be the unique right.

---

## Practical v0 model

### Recommended posture
- `RightRegistry` behaves as an **ERC-721-like unique position registry**
- rights carry a metadata URI/hash describing terms
- lifecycle state lives in protocol storage, not in token semantics alone
- partial consumption is tracked through protocol accounting / settlement state
- delegation remains explicit through `DelegationRegistry`
- packages remain separate structured objects rather than overloading the right token itself

### What should not be forced into v0
- fungible right classes before terms are standardized
- per-request token splitting for every consumption event
- trying to make token standard semantics carry the whole settlement model

---

## How partial consumption should work

A common objection to ERC-721-like rights is partial consumption.

That objection is real, but it does not kill the model.

The better posture is:
- keep the right as the canonical position object
- track remaining usable capacity in metadata-linked state or settlement/accounting state
- allow explicit protocol actions for split / tranche / package creation when needed

So the right is the durable container.
Consumption accounting is protocol state.

That is cleaner than pretending every partial usage should immediately become a fungible balance event.

---

## How packages fit

Packages should not force the core right representation decision.

Instead:
- underlying rights stay unique
- `PackageRegistry` references bundles, tranches, or strategies built from them
- package manifests can define allocation or slice behavior offchain / by hash reference
- future package formats may expose more class-like behavior without rewriting the base right model

---

## How future ERC-1155-like classes can emerge

If the protocol later discovers a genuinely homogeneous product such as:
- same issuer policy
- same workload class
- same windows or epoch cadence
- same fallback posture
- same settlement assumptions

then it can introduce:
- fungible wrappers
- issuance classes
- pooled inventory tokens
- venue-specific liquidity layers

But those should sit **on top of** or **alongside** the canonical unique-right layer, not replace it prematurely.

---

## v0 takeaway

Synthference rights should begin life on Base as **ERC-721-like unique positions with explicit protocol lifecycle state**.

That gives the protocol the best combination of:
- semantic honesty
- composability
- auditability
- settlement clarity
- room to evolve toward packages and later standardized classes

The mistake would be optimizing for fungibility before the protocol proves which rights are actually fungible.
