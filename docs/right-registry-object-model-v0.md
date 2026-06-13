# Synthference RightRegistry Object Model v0

## Goal

Turn the v0 onchain representation decision into a concrete `RightRegistry` object/state model for Base.

This document defines:
- the canonical right object posture
- what should be stored onchain
- what should remain offchain
- lifecycle enums
- core state transitions
- how consumption, split, freeze, and finalization should behave

This is still a protocol design document, not Solidity code.

---

## Core posture

`RightRegistry` should behave like an **ERC-721-like unique position registry with explicit protocol state layered on top**.

That means:
- each right has a unique canonical `rightId`
- ownership and approvals follow token-like expectations
- lifecycle, remaining capacity, and settlement-linked state live in protocol storage
- heavy policy detail remains offchain behind metadata references / hashes

The right is the durable onchain object.
The runtime semantics live partly in offchain manifests and partly in narrow protocol state.

---

## Design goals

1. **Canonical identity** - each right must be uniquely addressable
2. **Portable ownership** - wallets, venues, and agents should reason about ownership clearly
3. **Compact storage** - do not store the whole policy manifest onchain
4. **Legible lifecycle** - durable status must be easy to inspect
5. **Explicit consumption accounting** - partial use must be modeled cleanly
6. **Lineage support** - split, amendment, and package relationships must stay traceable
7. **Settlement compatibility** - right state must anchor cleanly to settlement outcomes

---

## Canonical object model

Each onchain right should be represented by a unique `rightId` with a stored record.

### Conceptual shape

```text
RightRecord {
  rightId
  issuerRef
  owner
  controller
  metadataHash
  metadataURI
  lifecycleStatus
  resourceUnit
  maxAmount
  remainingAmount
  windowStart
  windowEnd
  parentRightId
  lineageFlags
  freezeFlags
  finalizationRef
}
```

This is conceptual, not a literal storage layout.
The actual contract may pack, hash, or normalize some of these differently.

---

## Minimum onchain fields

## 1. Identity

### `rightId`
Unique canonical identifier for the right.

### `issuerRef`
Reference to issuer identity.
This may be:
- issuer address
- issuer registry id
- or both

### `owner`
Canonical owner of the right.

### `controller`
Optional explicit controller if the protocol wants a distinction between legal/economic owner and active controller.

### Why keep `controller`
Some rights may be owned by one party but operated by another system or vault.
If this distinction is not needed in early code, it can default to owner.
But the model should leave room for it.

---

## 2. Metadata integrity

### `metadataHash`
Canonical hash of the full right terms manifest.

### `metadataURI`
Optional URI for indexers, wallets, and applications.

### Why both
- hash gives integrity
- URI gives usability

The protocol should never rely on URI alone for durable truth.

---

## 3. Resource/accounting fields

### `resourceUnit`
Compact enum or code representing the primary accounting unit.
Examples:
- tokens
- requests
- jobs
- frames
- seconds

### `maxAmount`
Maximum deliverable amount for the right.

### `remainingAmount`
Remaining usable amount under protocol accounting.

### Why store these onchain
This is the minimum needed to make the right operationally legible without putting the whole policy manifest onchain.

It lets the chain answer:
- what is this right’s maximum capacity?
- how much is still usable?
- has it been fully consumed?

### What should stay offchain
Detailed resource semantics should stay in the metadata manifest:
- model class
- capability tags
- per-request limits
- provider constraints
- fallback policy details

---

## 4. Window fields

### `windowStart`
Start time of usability.

### `windowEnd`
End time of usability.

### Why store onchain
Window boundaries are durable economic truth and often matter for transfer, settlement, and expiry.

### What can stay offchain
More complex window semantics like rolling activation logic or epoch details can remain in the metadata manifest if needed, as long as onchain expiry semantics are still unambiguous enough.

---

## 5. Lifecycle state

### `lifecycleStatus`
Primary durable state enum.

Recommended v0 values:
- `Issued`
- `Active`
- `Frozen`
- `Expired`
- `FullyConsumed`
- `Finalized`
- `Burned`

### Meanings
- **Issued** - created but not yet active
- **Active** - usable under policy
- **Frozen** - temporarily non-transferable and/or unusable under policy
- **Expired** - window elapsed without remaining usable validity
- **FullyConsumed** - no remaining usable amount
- **Finalized** - fully settled as a durable completed state
- **Burned** - removed from active circulation by explicit burn path

### Notes
`Expired` and `FullyConsumed` are not the same.
A right can expire with leftover unused capacity.
A right can be fully consumed before the window ends.

---

## 6. Lineage fields

### `parentRightId`
Optional reference to the parent right if this right was created by split, tranche, or amendment flow.

### `lineageFlags`
Compact flags that indicate posture such as:
- original issuance
- split child
- amended child
- wrapped into package
- unwrapped from package

### Why it matters
Lineage becomes important fast for:
- auditability
- package correctness
- partial restructuring
- secondary market trust

---

## 7. Freeze/finality references

### `freezeFlags`
Compact bitfield or enum describing why the right is frozen.
Examples:
- compliance freeze
- dispute freeze
- issuer pause
- settlement lock

### `finalizationRef`
Optional reference to final settlement or terminal lifecycle state.
This may point to:
- settlement id
- settlement anchor id
- finalization hash

This helps indexers and applications connect the right to its terminal durable state.

---

## What should not be stored directly onchain in v0

Do not store these as full decomposed fields in the first contract unless proven necessary:
- full fallback policy object
- provider allow/deny lists
- routing hints
- proof requirement arrays
- detailed settlement policy text
- package composition details
- per-provider execution constraints
- large attestation bodies

Those belong in metadata manifests, issuer manifests, package manifests, and settlement manifests.

---

## Ownership and approval model

`RightRegistry` should support familiar token-like mechanics:
- owner
- approved operator
- transfer
- transfer approval

But the protocol must reserve the right to constrain transfers when lifecycle state requires it.

### Transfer gating examples
Transfers may be blocked when:
- status is `Frozen`
- status is `Finalized`
- status is `Burned`
- settlement/dispute lock is active
- issuer or governance policy explicitly disallows transfer for the right type

The point is to preserve portable ownership **without pretending every state is always freely transferable**.

---

## Core actions

## 1. Issue

Creates a new unique right.

### Inputs
- issuer ref
- initial owner/controller
- metadata hash / URI
- unit
- max amount
- initial remaining amount
- window start/end
- lineage refs if derived

### State effect
- create `RightRecord`
- set status to `Issued` or directly `Active` depending on issuance posture
- emit `RightIssued`

---

## 2. Activate

Moves an issued right into usable state.

### Why separate activation may matter
Useful for:
- pre-sale or reserved inventory
- rights requiring payment finality first
- issuance before a future activation timestamp

### State effect
- `Issued -> Active`
- emit `RightStatusChanged`

---

## 3. Transfer

Moves ownership under allowed conditions.

### State effect
- update owner/controller as policy requires
- emit `RightTransferred`

### Important note
Transfer should not rewrite lineage, accounting history, or settlement history.
Ownership changes; identity persists.

---

## 4. Consume

Records durable reduction in remaining usable amount.

### Inputs
- amount consumed
- optional settlement/request ref

### State effect
- decrement `remainingAmount`
- if `remainingAmount == 0`, transition to `FullyConsumed`
- optionally attach or emit a consumption/settlement linkage event

### Important nuance
`Consume` should represent durable recognized usage, not every low-level runtime micro-event.
It is the accounting/finality layer, not the live execution trace.

---

## 5. Split

Creates one or more child rights from a parent right.

### Why split exists
Needed when:
- carving off part of remaining capacity
- creating tranches
- preparing package components
- enabling partial transfer without selling the full right

### State effect
- parent remaining amount reduced or parent transitioned to a derived state
- child right(s) minted with `parentRightId` set
- lineage flags updated
- emit `RightSplit` or `RightIssued` + lineage event

### Recommendation
Keep split explicit.
Do not silently emulate it through fungible balances.

---

## 6. Freeze / Unfreeze

Temporarily blocks some actions.

### Freeze should be usable for
- disputes
- issuer intervention
- compliance lock
- settlement inconsistency investigation

### State effect
- status becomes `Frozen`
- freeze flags updated
- emit `RightFrozen`

### Unfreeze
- restore appropriate prior active state when allowed
- emit `RightStatusChanged`

---

## 7. Expire

Marks a right as expired once its usable window ends.

### State effect
- `Issued|Active|Frozen -> Expired` when policy conditions are met
- emit `RightStatusChanged`

### Important note
Expiry should not require that `remainingAmount == 0`.
It only means the usable window is over.

---

## 8. Finalize

Marks terminal settled posture.

### When used
After protocol-level settlement determines the right is durably complete or terminal for lifecycle purposes.

### State effect
- set `finalizationRef`
- move to `Finalized` when appropriate
- emit `RightStatusChanged` or `RightFinalized`

### Note
Not every consumed right must immediately be `Finalized`.
Finalization is a stronger terminal statement than simple depletion.

---

## 9. Burn

Destroys the right from active circulation.

### When appropriate
- invalid issuance rollback
- redeemed-and-retired posture
- migration to successor representation
- policy-driven cleanup after full finalization

### State effect
- `Burned`
- emit `RightBurned`

### Important note
Burn should be rare and explicit.
It should not be the default substitute for every terminal state.

---

## Suggested events

Recommended v0 event surface:
- `RightIssued`
- `RightTransferred`
- `RightApprovalSet`
- `RightStatusChanged`
- `RightConsumed`
- `RightSplit`
- `RightFrozen`
- `RightUnfrozen`
- `RightFinalized`
- `RightBurned`

### Why add `RightConsumed` and `RightSplit`
The earlier contract-surface doc implied them but did not make them explicit enough.
For indexers and secondary markets, those two events matter a lot.

---

## Suggested enums

## Resource unit
Examples:
- `Tokens`
- `Requests`
- `Jobs`
- `Frames`
- `Seconds`
- `Minutes`
- `Custom`

## Lifecycle status
- `Issued`
- `Active`
- `Frozen`
- `Expired`
- `FullyConsumed`
- `Finalized`
- `Burned`

## Freeze reason
- `None`
- `IssuerPause`
- `Dispute`
- `Compliance`
- `SettlementLock`
- `Governance`
- `Custom`

---

## State transition posture

A useful simplified transition map:

```text
Issued -> Active
Issued -> Frozen
Issued -> Burned

Active -> Frozen
Active -> Expired
Active -> FullyConsumed
Active -> Finalized

Frozen -> Active
Frozen -> Expired
Frozen -> Finalized
Frozen -> Burned

FullyConsumed -> Finalized
FullyConsumed -> Burned

Expired -> Finalized
Expired -> Burned
```

### Notes
- `Finalized` and `Burned` should generally be terminal
- `FullyConsumed` is operationally terminal for use, but not necessarily terminal for settlement or archival posture
- `Frozen` should be reversible unless the protocol escalates to a stronger terminal state

---

## Relationship to metadata manifests

The onchain object should only store the minimum durable fields needed for canonical truth.

The full manifest should still define:
- workload class
- service/latency/privacy posture
- routing constraints
- fallback policy
- settlement policy
- detailed limits
- descriptive metadata

So the contract stores **durable anchors**.
The manifest stores **rich semantics**.

---

## Relationship to SettlementAnchor

`RightRegistry` should not attempt to fully internalize settlement logic.

Instead:
- `SettlementAnchor` records the canonical finalized settlement commitments
- `RightRegistry` references those commitments where lifecycle requires it
- consumption and finalization should be able to cite settlement/request ids cleanly

This preserves separation of concerns.

---

## Relationship to PackageRegistry

Packages should reference underlying rights, not replace them.

That means:
- `RightRegistry` stays the source of canonical right identity
- package manifests/records define composition and slicing logic
- splits can create package-ready child rights when needed
- package transfer should not erase underlying right lineage

---

## v0 recommendation

The first real `RightRegistry` should be:
- **ERC-721-like in identity and transfer posture**
- **protocol-specific in lifecycle/accounting state**
- **manifest-driven for rich policy semantics**
- **lineage-aware for split/package/finalization flows**

That is the smallest model that still tells the truth about what Synthference rights actually are.
