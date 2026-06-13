# Synthference RightRegistry Solidity Surface v0

## Goal

Translate the `RightRegistry` object model into a first Solidity-oriented storage, interface, and role surface for a Base deployment.

This document is still pre-code, but it is intentionally shaped so the next step can become a contract draft with minimal ambiguity.

---

## Core posture

`RightRegistry` should be implemented as an **ERC-721-compatible ownership surface with protocol-specific right state layered around it**.

That means:
- reuse familiar NFT ownership/approval semantics where they help
- add right-specific storage for accounting, lifecycle, and lineage
- keep heavy manifests offchain behind `metadataHash` and optional `metadataURI`
- let settlement and delegation modules remain separate contracts

This is not "just an NFT contract."
It is a protocol registry that **borrows ERC-721 where ownership portability is useful**.

---

## High-level contract shape

### Recommended inheritance posture
A practical v0 draft would likely build on:
- `ERC721`
- optionally `AccessControl`
- optionally `ERC165`

Potential later mixins:
- pausable module
- upgradeable proxy posture
- royalty or venue hooks only if actually needed later

### Recommendation
Keep v0 narrow:
- standard ERC-721 ownership + approvals
- explicit protocol roles for mint/freeze/finalize/consume
- custom right record mappings

---

## Storage model

## 1. Core record

```solidity
struct RightRecord {
    uint64 issuerId;
    uint8 resourceUnit;
    uint8 lifecycleStatus;
    uint8 freezeReason;
    uint32 lineageFlags;
    uint128 maxAmount;
    uint128 remainingAmount;
    uint64 windowStart;
    uint64 windowEnd;
    uint256 parentRightId;
    bytes32 metadataHash;
    bytes32 finalizationRef;
    address controller;
}
```

### Notes
This is an oriented shape, not a finalized packing guarantee.

Key ideas:
- keep numerics compact where reasonable
- keep `metadataHash` and `finalizationRef` fixed-size
- avoid long strings in the primary struct
- keep `controller` explicit even if it defaults to owner

### Why no `metadataURI` in the core struct
Storing strings inline is expensive and ugly for packing.
Better v0 posture:
- core struct keeps `metadataHash`
- separate mapping stores optional URI

---

## 2. Supplemental mappings

```solidity
mapping(uint256 => RightRecord) internal _rights;
mapping(uint256 => string) internal _metadataURIs;
mapping(uint256 => uint256[]) internal _childRights;
mapping(uint256 => bool) internal _frozenTransferOverride;
```

### Recommended minimum
At minimum:
- `_rights`
- `_metadataURIs`

### Optional early mappings
- `_childRights` if onchain lineage enumeration matters early
- `_frozenTransferOverride` only if nuanced transfer locks are needed beyond status/freezeReason

### Recommendation
Do **not** over-index on enumerable child arrays unless a real onchain consumer needs them.
Event-driven lineage plus `parentRightId` may be enough for v0.

---

## 3. Global counters / registries

```solidity
uint256 internal _nextRightId;
address public issuerRegistry;
address public settlementAnchor;
address public delegationRegistry;
```

### Why explicit external registry addresses
The `RightRegistry` should know its sibling surfaces enough to:
- validate authorized callers
- emit coherent references
- support module upgrades later through governance/admin

---

## Enums

## 1. Resource unit

```solidity
enum ResourceUnit {
    Tokens,
    Requests,
    Jobs,
    Frames,
    Seconds,
    Minutes,
    Custom
}
```

## 2. Lifecycle status

```solidity
enum RightStatus {
    Issued,
    Active,
    Frozen,
    Expired,
    FullyConsumed,
    Finalized,
    Burned
}
```

## 3. Freeze reason

```solidity
enum FreezeReason {
    None,
    IssuerPause,
    Dispute,
    Compliance,
    SettlementLock,
    Governance,
    Custom
}
```

### Why enums matter
Even if the implementation eventually stores raw integers for packing, the spec should speak in enums so the contract surface stays understandable.

---

## Lineage flags

Recommended bit flags:

```text
1 << 0  ORIGINAL_ISSUANCE
1 << 1  SPLIT_CHILD
1 << 2  AMENDED_CHILD
1 << 3  PACKAGED
1 << 4  UNPACKAGED
1 << 5  MIGRATED
```

### Why flags instead of separate booleans
Cheaper, more extensible, and easier to preserve across derived-right flows.

---

## Roles and authority

## Recommended v0 roles

### `DEFAULT_ADMIN_ROLE`
Can:
- set registry/module addresses
- manage protocol roles
- perform emergency admin actions if the system chooses AccessControl

### `ISSUER_ROLE`
Can:
- issue rights directly if authorized
- possibly activate rights depending on issuance flow

### `CONSUMER_ROLE`
Can:
- record recognized consumption

This should usually be held by a trusted settlement/finalization surface, not arbitrary runtime adapters.

### `FREEZER_ROLE`
Can:
- freeze/unfreeze rights under allowed reasons

### `FINALIZER_ROLE`
Can:
- mark finalization refs
- transition rights into final lifecycle states when settlement says so

### `BURNER_ROLE`
Can:
- burn rights where policy allows

---

## Authority model recommendation

Do **not** let arbitrary ERC-721 owners directly call every lifecycle mutation.

Better posture:
- owners control transfer/approval
- protocol-authorized actors control issuance/accounting/finalization transitions
- some owner-triggered actions may exist later for packaging or voluntary burns, but keep v0 conservative

This avoids turning the registry into a self-asserted accounting surface.

---

## Input structs

## 1. Issue params

```solidity
struct IssueRightParams {
    uint64 issuerId;
    address to;
    address controller;
    ResourceUnit resourceUnit;
    uint128 maxAmount;
    uint128 initialRemainingAmount;
    uint64 windowStart;
    uint64 windowEnd;
    bytes32 metadataHash;
    string metadataURI;
    uint256 parentRightId;
    uint32 lineageFlags;
    bool activateImmediately;
}
```

### Notes
- `initialRemainingAmount` should usually equal `maxAmount` unless issuance is derived from an already reduced parent or special migration flow
- `controller == address(0)` can default to `to`

---

## 2. Consume params

```solidity
struct ConsumeRightParams {
    uint256 rightId;
    uint128 amount;
    bytes32 settlementRef;
}
```

### Why `settlementRef`
Consumption should be tied to durable accounting recognition, not free-floating mutation.

---

## 3. Split params

```solidity
struct SplitRightParams {
    uint256 parentRightId;
    address[] recipients;
    uint128[] amounts;
    bytes32[] childMetadataHashes;
    string[] childMetadataURIs;
}
```

### Recommendation
Keep split opinionated:
- explicit recipient list
- explicit amounts
- sum must not exceed parent remaining amount
- child rights inherit core posture from parent unless explicitly overridden by protocol rules

---

## Events

## Recommended event surface

```solidity
event RightIssued(
    uint256 indexed rightId,
    uint64 indexed issuerId,
    address indexed owner,
    bytes32 metadataHash,
    uint128 maxAmount,
    uint128 remainingAmount
);

event RightActivated(uint256 indexed rightId);

event RightConsumed(
    uint256 indexed rightId,
    uint128 amount,
    uint128 remainingAmount,
    bytes32 indexed settlementRef
);

event RightSplit(
    uint256 indexed parentRightId,
    uint256 indexed childRightId,
    address indexed recipient,
    uint128 amount
);

event RightFrozen(uint256 indexed rightId, FreezeReason reason);

event RightUnfrozen(uint256 indexed rightId);

event RightFinalized(uint256 indexed rightId, bytes32 indexed finalizationRef);

event RightStatusChanged(uint256 indexed rightId, RightStatus oldStatus, RightStatus newStatus);

event RightControllerUpdated(uint256 indexed rightId, address indexed oldController, address indexed newController);

event RegistryDependencyUpdated(bytes32 indexed key, address indexed oldValue, address indexed newValue);
```

### Notes
Standard ERC-721 `Transfer` and approval events still exist underneath.
These events capture protocol semantics the token standard does not express.

---

## External/public view functions

## Minimum getters

```solidity
function getRight(uint256 rightId) external view returns (RightRecord memory);
function remainingAmount(uint256 rightId) external view returns (uint128);
function maxAmount(uint256 rightId) external view returns (uint128);
function lifecycleStatus(uint256 rightId) external view returns (RightStatus);
function freezeReasonOf(uint256 rightId) external view returns (FreezeReason);
function controllerOf(uint256 rightId) external view returns (address);
function metadataHashOf(uint256 rightId) external view returns (bytes32);
function metadataURIOf(uint256 rightId) external view returns (string memory);
function parentRightOf(uint256 rightId) external view returns (uint256);
function finalizationRefOf(uint256 rightId) external view returns (bytes32);
```

### Recommendation
Expose enough for indexers and apps without making consumers reconstruct core state from many tiny calls.
A `getRight` aggregate getter is worth it.

---

## External/public mutating functions

## 1. Issue

```solidity
function issueRight(IssueRightParams calldata params) external returns (uint256 rightId);
```

## 2. Activate

```solidity
function activateRight(uint256 rightId) external;
```

## 3. Consume

```solidity
function consumeRight(ConsumeRightParams calldata params) external;
```

## 4. Split

```solidity
function splitRight(SplitRightParams calldata params) external returns (uint256[] memory childRightIds);
```

## 5. Freeze / Unfreeze

```solidity
function freezeRight(uint256 rightId, FreezeReason reason) external;
function unfreezeRight(uint256 rightId) external;
```

## 6. Expire

```solidity
function expireRight(uint256 rightId) external;
```

### Recommendation
This can be permissionless if it only checks objective time conditions and updates status safely.
That keeps stale rights from depending on operator cleanup.

## 7. Finalize

```solidity
function finalizeRight(uint256 rightId, bytes32 finalizationRef) external;
```

## 8. Burn

```solidity
function burnRight(uint256 rightId) external;
```

## 9. Controller update

```solidity
function setController(uint256 rightId, address newController) external;
```

### Recommendation
Be careful here.
This may need to be:
- owner-controlled
- approved-operator controlled
- or protocol-role controlled depending on intended semantics

For v0, defaulting to owner-or-approved is probably cleanest unless controller has high protocol significance.

---

## Transfer hook posture

The contract should override transfer checks so it can reject transfers when protocol state forbids them.

### Recommended blocked states
- `Frozen`
- `Finalized`
- `Burned`

### Conditional blocked states
- `Expired` depending on whether expired rights still trade as claims/history artifacts
- `FullyConsumed` depending on whether depleted rights still transfer as collectible/history objects

### Recommendation
For v0:
- block transfer on `Frozen`, `Finalized`, `Burned`
- allow governance/policy to decide later whether `Expired` or `FullyConsumed` remain transferable

---

## Validation rules

## Issue validation
- `to != address(0)`
- `maxAmount > 0`
- `initialRemainingAmount <= maxAmount`
- `windowEnd > windowStart` unless a later schema explicitly supports open-ended posture
- `metadataHash != bytes32(0)`

## Consume validation
- status must be `Active`
- amount must be > 0
- amount must be <= remaining amount
- settlement ref should be nonzero for protocol-recognized durable consumption

## Split validation
- parent status must be `Active`
- total split amount must be > 0
- total split amount must be <= parent remaining amount
- array lengths must match
- child metadata hashes should be present

## Finalize validation
- right must not already be `Burned`
- finalization ref must be nonzero
- caller must have `FINALIZER_ROLE`

---

## Storage/interface tradeoffs

## Why keep strings out of the core struct
Cheaper storage layout and easier future upgrades.

## Why keep `remainingAmount` onchain
Because it is durable economic truth, not just UI metadata.

## Why keep `controller` explicit
Because delegation, vault ownership, and operator patterns get awkward fast if owner is forced to do all conceptual jobs.

## Why not put fallback policy onchain
Because that is rich policy configuration better represented in hashed manifests.

---

## Relationship to sibling contracts

## `IssuerRegistry`
- validates issuer IDs / issuer status
- may gate `issueRight`

## `DelegationRegistry`
- should handle scoped execution authority
- `RightRegistry` should not try to replace it with overloaded token approvals

## `SettlementAnchor`
- should be the canonical source for finalized settlement commitments
- `consumeRight` and `finalizeRight` should reference settlement outputs rather than absorb the entire settlement model internally

---

## Recommended v0 implementation sequence

1. implement storage structs + enums
2. implement issuance + getters
3. implement transfer gating hooks
4. implement consume + split
5. implement freeze/finalize/burn
6. wire issuer/settlement registry references
7. add tests for lifecycle invariants and split/accounting correctness

---

## v0 takeaway

The Solidity-oriented `RightRegistry` should be:
- **ERC-721 compatible at the ownership layer**
- **custom at the lifecycle/accounting layer**
- **module-aware but not module-bloated**
- **ready for a first real contract draft without dragging in the whole protocol at once**
