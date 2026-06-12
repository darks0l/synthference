# Synthference Base Contract Surface v0

## Goal

Sketch the first practical contract surface for Synthference on Base.

This is not a full Solidity implementation.
It defines the contract responsibilities and object boundaries that would let the protocol anchor rights, delegation, packaging, and settlement cleanly onchain.

---

## Design principles

1. **Keep the anchor layer small** - contracts should capture durable truth, not operational noise
2. **Favor explicit object boundaries** - rights, packages, delegation, and settlement should not blur together
3. **Reference heavy data instead of storing it all** - large detail should live offchain behind stable references or hashes
4. **Make authority legible** - ownership, operator rights, delegation, and issuer roles should be obvious
5. **Leave room for multiple issuance styles** - centralized, federated, enterprise, and hybrid paths should all fit

---

## Recommended initial contracts

### 1. `RightRegistry`
Canonical registry for Synthference rights.

### 2. `IssuerRegistry`
Tracks approved issuers and attestation references.

### 3. `DelegationRegistry`
Tracks scoped right-usage authority.

### 4. `PackageRegistry`
Tracks package lineage, references, and transfer hooks.

### 5. `SettlementAnchor`
Anchors finalized settlement results and dispute/finality state.

Optional later:
- `VenueEscrow`
- `DisputeModule`
- `RegistryGovernor`

---

## Contract 1: `RightRegistry`

### Responsibilities
- mint/register a right
- track canonical owner/controller
- expose metadata reference or metadata hash
- support transfer / approval / burn / freeze hooks as policy allows
- expose right lifecycle status at a durable level

### Minimum stored data
- `rightId`
- issuer address or issuer registry reference
- owner/controller
- metadata URI or metadata hash
- lifecycle status
- optional class/type flags

### Suggested events
- `RightIssued`
- `RightTransferred`
- `RightApprovalSet`
- `RightStatusChanged`
- `RightMetadataUpdated` (if updateable)
- `RightFrozen`
- `RightBurned`

### Notes
The metadata should describe or point to:
- workload class
- limits
- window
- fallback posture
- settlement baseline
- assurance reference

But those details do not all need to be individually stored in contract storage if a stable hash or URI strategy is used.

---

## Contract 2: `IssuerRegistry`

### Responsibilities
- register authorized issuers
- expose issuer class and policy metadata
- reference offchain attestation manifests
- support issuer pause/revoke status

### Minimum stored data
- issuer id or address
- active/revoked status
- issuer type
- attestation URI/hash
- optional policy hash

### Suggested events
- `IssuerRegistered`
- `IssuerUpdated`
- `IssuerRevoked`
- `IssuerRestored`

### Why it matters
This lets holders and venues distinguish rights from recognized issuers versus arbitrary untrusted issuers.

---

## Contract 3: `DelegationRegistry`

### Responsibilities
- authorize scoped execution or control rights to another actor
- define limits and expiry
- support revocation
- let adapters or control-plane actors verify authority cheaply

### Minimum stored data
- delegation id
- source right or package ref
- delegator
- delegate
- amount or scope limit
- expiry
- permission flags

### Suggested permissions
- use right
- transfer right
- create request
- sub-delegate
- package into bundle

### Suggested events
- `DelegationCreated`
- `DelegationUsed`
- `DelegationRevoked`
- `DelegationExpired`

### Notes
In v0, `DelegationUsed` may only need to be emitted by settlement/finalization layers rather than every runtime invocation, depending on gas posture.

---

## Contract 4: `PackageRegistry`

### Responsibilities
- register package identity
- track package owner/controller
- reference package composition manifest
- support transfer and optional split/merge bookkeeping
- preserve lineage to underlying rights or parent packages

### Minimum stored data
- package id
- owner/controller
- package type
- composition hash or URI
- lifecycle status

### Suggested events
- `PackageCreated`
- `PackageTransferred`
- `PackageSplit`
- `PackageMerged`
- `PackageFinalized`

### Notes
Package composition itself may be too dynamic or too verbose for dense onchain storage.
In many cases, a manifest hash plus indexer support is the right tradeoff.

---

## Contract 5: `SettlementAnchor`

### Responsibilities
- anchor final settlement outcomes
- record settlement hash / receipt hash / manifest hash
- record final classification
- expose dispute/finality status
- optionally record batched settlement roots

### Minimum stored data
- settlement id or request id
- right/package refs involved
- classification enum
- settlement hash
- finalization status
- optional dispute status

### Suggested events
- `SettlementAnchored`
- `SettlementFinalized`
- `SettlementDisputed`
- `SettlementReversed`

### Notes
The chain does not need every execution detail.
It needs enough commitment data that an indexer or verifier can link the chain result back to the offchain receipt and proof set.

---

## Suggested object model choices

### Rights as unique positions
Strong default for v0.
A right is likely best modeled as a unique position rather than a fungible balance class.

Why:
- rights differ by policy shape
- windows and fallback terms can vary
- partial consumption and amendment lineage matter

This leans toward an ERC-721-like or custom unique-record posture.

### Packages as unique containers
Also a strong default.
A package is best thought of as a structured container/lineage object.

### Fungible classes later
If the protocol later defines highly standardized right classes, fungible wrappers or ERC-1155-like classes could make sense for specific tiers.
But that should come after the unique-position model is proven.

---

## Minimal enums / flags

### Right lifecycle status
- `Issued`
- `Active`
- `Frozen`
- `Expired`
- `FullyConsumed`
- `Finalized`
- `Burned`

### Settlement classification
- `Full`
- `Fallback`
- `Partial`
- `Failed`
- `Expired`
- `Cancelled`

### Package type
- `Bundle`
- `Slice`
- `Tranche`
- `DelegationWrapper`
- `Strategy`

---

## Metadata references

The contract surface should probably use one or both of:
- content-addressed hash
- metadata URI

### Good pattern
Store:
- content hash onchain
- human/indexer-friendly URI optionally

That gives integrity plus usability.

---

## Upgrade posture

The Base contract layer should move slower than the control plane.

Good v0 strategy:
- keep storage models narrow
- put detailed policy and proof manifests offchain
- reserve upgrade room for package semantics and dispute modules
- avoid overfitting early contracts to one execution provider or venue pattern

---

## Security notes

### Avoid storing mutable operational assumptions onchain
Do not treat chain storage as the live source of route availability or provider health.

### Separate mint authority from settlement authority
Issuers, settlement relayers, and governance actors may need distinct roles.

### Expect partial trust surfaces
Even with onchain contracts, offchain adapters and relayers remain meaningful trust boundaries.
Design roles and events to expose that clearly.

---

## Open questions

- ERC-721-style rights, ERC-1155-style classes, or fully custom registry?
- should delegation live inside `RightRegistry` approvals or a dedicated `DelegationRegistry`?
- how much package composition should be explicitly decomposable onchain?
- should settlement anchoring support Merkle roots for batch posting from day one?
- when should a dispute module be separate versus embedded in settlement anchoring?

---

## v0 takeaway

The Base contract layer should center on five durable surfaces:
**rights, issuers, delegations, packages, and settlement anchors**.

That is enough to give Synthference portable ownership and settlement rails on Base without pretending the whole compute runtime belongs onchain.
