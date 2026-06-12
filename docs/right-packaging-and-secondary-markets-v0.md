# Synthference Right Packaging and Secondary Market Semantics v0

## Goal

Define how Synthference rights may be packaged, grouped, split, transferred, or exchanged in secondary contexts without losing their bounded execution and settlement meaning.

This document does not assume that every deployment needs an open marketplace.
It defines the semantics required if rights are to move beyond a one-issuer, one-holder, one-use posture.

---

## Why this matters

If Synthference rights are useful, people will want to do more than simply consume them directly.

Examples:
- an app wants to bundle multiple rights into one service plan
- an agent wants to reserve future compute and later reallocate it across sub-agents
- a coordinator wants to package premium baseline plus overflow rights into one product tier
- a holder wants to transfer unused rights to another participant
- a venue wants to enable secondary exchange of standardized rights

Without clear packaging semantics, these behaviors become ambiguous fast.
The system risks turning bounded rights into vague wrappers that break routing and settlement clarity.

---

## Design principles

1. **The underlying right stays legible** - packaging should not erase the execution meaning of the underlying rights
2. **Boundedness survives packaging** - wrappers must not create hidden infinite claims
3. **Settlement remains traceable** - packaged rights must still resolve back to concrete fulfillment and proof paths
4. **Transferability is policy-bound** - not every right should be freely transferable or splittable
5. **Composability without confusion** - packaging should enable useful higher-level products without collapsing important distinctions

---

## Core idea

A package is not a new metaphysical asset class.
It is a structured control surface over one or more underlying rights.

Packaging should preserve answers to:
- what underlying rights exist?
- who currently controls them?
- how much usable balance remains?
- what routing and fallback limits still apply?
- what settlement paths still govern them?

If a wrapper cannot answer those questions, it is too lossy for protocol use.

---

## Core packaging operations

### 1. Bundling
Multiple rights are grouped into a single package reference.

### 2. Slicing
A right or package is split into smaller units or sub-rights.

### 3. Tranching
A package defines priority or quality layers over underlying rights.

### 4. Transfer
Control over a right or package moves from one holder to another.

### 5. Delegation
A holder grants controlled usage rights without full transfer of ownership/control.

### 6. Exchange
A venue or bilateral flow enables rights to be sold, swapped, or reassigned.

---

## Packaging object

A package should be explicit in the registry.

```json
{
  "packageId": "pkg_01",
  "version": "synthference/package/v0",
  "packageType": "bundle|slice|tranche|delegation|strategy",
  "holder": {
    "holderType": "app",
    "holderId": "app_01"
  },
  "components": [
    {
      "rightRef": "sr_01",
      "allocatedAmount": 50000
    },
    {
      "rightRef": "sr_02",
      "allocatedAmount": 2
    }
  ],
  "packagePolicy": {
    "transferable": true,
    "splittable": true,
    "delegable": false
  },
  "metadata": {
    "label": "standard-tier-pack"
  }
}
```

---

## Packaging types

### 1. `bundle`
A simple grouped set of rights offered or managed together.

Useful for:
- product plans
- app-owned capacity pools
- multi-workload service packages

### 2. `slice`
A smaller derived allocation carved out of a larger right or package.

Useful for:
- team sub-allocation
- agent task budgeting
- reselling only unused capacity portions

### 3. `tranche`
A layered package where fulfillment preference or fallback posture differs by tier.

Useful for:
- premium vs standard lanes
- baseline vs overflow service tiers
- quality or latency segmented products

### 4. `delegation`
The original holder stays in control, but grants scoped execution authority to another actor.

Useful for:
- parent agent to child agent budget
- app to user-session execution authorization
- enterprise team allocation without permanent transfer

### 5. `strategy`
A higher-level package that applies routing or rebalancing logic over a set of rights.

Useful for:
- private-first then hosted fallback
- reserve premium then spill into standard
- workload-aware dynamic allocation

---

## Bundle semantics

A bundle should not imply homogeneity unless stated.

A bundle may contain:
- different workload classes
- different latency bands
- different privacy modes
- different windows
- different fallback rules

Therefore, bundle-level routing should either:
- pick a compatible component right explicitly, or
- expose a package policy that defines valid selection order or constraints

A bundle is not automatically one fungible pool.

---

## Slice semantics

Slicing should preserve lineage.

### Requirements
A slice should record:
- source right or source package
- allocated amount
- remaining amount on parent
- whether the slice is independent or still parent-constrained

### Important distinction
A slice can be:
- **detached**: new independent right/package identity with explicit lineage
- **attached**: scoped sub-allocation still governed by the parent's lifecycle

This matters for transfer, settlement, and finalization.

---

## Tranche semantics

Tranching is useful when a package offers layered service quality or execution preference.

### Example
A packaged service plan could define:
- first 100k tokens from premium interactive reserved capacity
- overflow 400k tokens from standard interactive or async fallback capacity

### Why it matters
This lets one product present a simple surface while still keeping route priority and fallback behavior explicit underneath.

### Constraint
A tranche wrapper should not hide that lower tiers may have materially different proof, latency, or settlement behavior.

---

## Delegation semantics

Delegation is not full transfer.

### Delegation should define
- who may use the delegated capacity
- maximum units or budget
- allowed workload classes
- time window
- revocation rules
- whether fallback or transfer is allowed downstream

### Good fit
Delegation is often the cleanest primitive for agent-native systems because it allows controlled execution authority without requiring full asset transfer each time.

---

## Transferability policy

Not all rights should move freely.

A right or package should be able to declare:
- `transferable: true|false`
- `splittable: true|false`
- `delegable: true|false`
- `requiresIssuerConsent: true|false`
- `requiresRegistryAcknowledgment: true|false`

### Reasons for restricting transfer
- privacy-sensitive supply
- enterprise internal-only rights
- regulatorily constrained usage
- issuer-guaranteed premium lanes that depend on holder qualification

---

## Secondary market semantics

A secondary market is any context where rights or packages change hands outside their original issuance moment.

### v0 does not require
- order books
- AMMs
- open public venues
- tokenization on a chain

It only requires that if secondary exchange occurs, the semantics stay clear.

### Minimum secondary-market requirements
A secondary venue or bilateral transfer flow should preserve:
- underlying right references
- current usable balance
- transfer restrictions
- amendment/finalization state
- settlement exposure state
- lineage to prior holders or packages when relevant

---

## Price discovery vs protocol meaning

The protocol does not need to define pricing logic.

But it should define what is being transferred.

For example, a secondary buyer should be able to know:
- whether they are buying a direct right
- a slice of a right
- a package of heterogeneous rights
- a delegation-limited usage claim
- a tranche with structured fallback behavior

That semantic clarity matters more than defining one market mechanism.

---

## Fungibility boundaries

Rights should only be treated as fungible when their relevant policy shape is sufficiently aligned.

### Likely fungibility dimensions
- same workload class
- same quality/latency profile
- same privacy class
- same usable window shape
- same fallback posture
- compatible settlement proof baseline

If those differ materially, the system should resist pretending the rights are interchangeable.

---

## Registry implications

Packages and transfers should appear in registry history explicitly.

Useful event patterns include:
- `package.created`
- `package.amended`
- `package.split`
- `package.transferred`
- `right.delegated`
- `right.transferred`
- `package.finalized`

This prevents secondary activity from becoming invisible side state.

---

## Routing implications

Routing against packaged rights should remain deterministic enough to inspect.

Examples:
- a bundle should indicate which underlying right was selected
- a tranche should record which tier fulfilled the request
- a strategy package should record which branch/rule fired
- a delegated right should record the delegator lineage when relevant

---

## Settlement implications

Settlement should still happen against concrete delivered units and concrete underlying rights.

Packages can shape allocation or holder control, but they should not erase:
- which right funded the execution
- which fallback path was used
- which settlement policy actually applied

A packaged surface can be user-friendly.
The settlement substrate still needs precision.

---

## Safe v0 posture

For v0, the safest packaging progression is usually:

1. direct rights only
2. simple bundles and delegations
3. explicit slices and tranches
4. broader secondary exchange semantics
5. higher-level strategy packages after routing and settlement behavior are already trustworthy

This progression reduces the chance of inventing wrappers that outrun the protocol's ability to explain them.

---

## Open questions

- should packages be first-class objects in the base schema or only registry extensions?
- when should a slice become a new right versus a package-scoped allocation?
- should transfer restrictions inherit automatically from the strictest underlying component?
- how should partial settlement work inside heterogeneous bundles?
- what minimum disclosure is required before a packaged right can be listed on a secondary venue?

---

## v0 takeaway

Packaging is useful, but it must stay honest.

Synthference rights can be bundled, sliced, delegated, and exchanged — as long as the protocol preserves lineage, constraints, and settlement meaning.

The goal is not to create vague wrappers over compute.
It is to make higher-level control over bounded compute rights possible without breaking the underlying logic.
