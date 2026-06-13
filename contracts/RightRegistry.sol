// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title Synthference RightRegistry
/// @notice ERC-721 based registry draft for unique Synthference rights.
/// @dev This draft replaces the placeholder ownership/admin plumbing with
/// OpenZeppelin ERC721 + AccessControl, but it still expects sibling protocol
/// surfaces (IssuerRegistry, DelegationRegistry, SettlementAnchor) to be wired later.
contract RightRegistry is ERC721, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant FINALIZER_ROLE = keccak256("FINALIZER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    enum ResourceUnit {
        Tokens,
        Requests,
        Jobs,
        Frames,
        Seconds,
        Minutes,
        Custom
    }

    enum RightStatus {
        Issued,
        Active,
        Frozen,
        Expired,
        FullyConsumed,
        Finalized,
        Burned
    }

    enum FreezeReason {
        None,
        IssuerPause,
        Dispute,
        Compliance,
        SettlementLock,
        Governance,
        Custom
    }

    uint32 internal constant LINEAGE_ORIGINAL_ISSUANCE = 1 << 0;
    uint32 internal constant LINEAGE_SPLIT_CHILD = 1 << 1;
    uint32 internal constant LINEAGE_AMENDED_CHILD = 1 << 2;
    uint32 internal constant LINEAGE_PACKAGED = 1 << 3;
    uint32 internal constant LINEAGE_UNPACKAGED = 1 << 4;
    uint32 internal constant LINEAGE_MIGRATED = 1 << 5;

    struct RightRecord {
        uint64 issuerId;
        ResourceUnit resourceUnit;
        RightStatus lifecycleStatus;
        FreezeReason freezeReason;
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

    struct ConsumeRightParams {
        uint256 rightId;
        uint128 amount;
        bytes32 settlementRef;
    }

    struct SplitRightParams {
        uint256 parentRightId;
        address[] recipients;
        uint128[] amounts;
        bytes32[] childMetadataHashes;
        string[] childMetadataURIs;
    }

    uint256 internal _nextRightId;

    address public issuerRegistry;
    address public settlementAnchor;
    address public delegationRegistry;

    mapping(uint256 => RightRecord) internal _rights;
    mapping(uint256 => string) internal _metadataURIs;

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

    error ZeroAddress();
    error InvalidAmount();
    error InvalidWindow();
    error InvalidMetadataHash();
    error RightDoesNotExist(uint256 rightId);
    error TransferBlocked(RightStatus status);
    error InvalidStatus(RightStatus current);
    error InvalidSettlementRef();
    error SplitArrayLengthMismatch();
    error SplitAmountExceeded();
    error FreezeReasonRequired();
    error UnknownRegistryDependency(bytes32 key);

    constructor(address admin_) ERC721("Synthference Right", "SRIGHT") {
        if (admin_ == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(REGISTRY_ADMIN_ROLE, admin_);
        _grantRole(ISSUER_ROLE, admin_);
        _grantRole(CONSUMER_ROLE, admin_);
        _grantRole(FREEZER_ROLE, admin_);
        _grantRole(FINALIZER_ROLE, admin_);
        _grantRole(BURNER_ROLE, admin_);

        _nextRightId = 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRegistryDependency(bytes32 key, address newValue) external onlyRole(REGISTRY_ADMIN_ROLE) {
        address oldValue;

        if (key == keccak256("issuerRegistry")) {
            oldValue = issuerRegistry;
            issuerRegistry = newValue;
        } else if (key == keccak256("settlementAnchor")) {
            oldValue = settlementAnchor;
            settlementAnchor = newValue;
        } else if (key == keccak256("delegationRegistry")) {
            oldValue = delegationRegistry;
            delegationRegistry = newValue;
        } else {
            revert UnknownRegistryDependency(key);
        }

        emit RegistryDependencyUpdated(key, oldValue, newValue);
    }

    function issueRight(IssueRightParams calldata params) external onlyRole(ISSUER_ROLE) returns (uint256 rightId) {
        if (params.to == address(0)) revert ZeroAddress();
        if (params.maxAmount == 0) revert InvalidAmount();
        if (params.initialRemainingAmount > params.maxAmount) revert InvalidAmount();
        if (params.windowEnd <= params.windowStart) revert InvalidWindow();
        if (params.metadataHash == bytes32(0)) revert InvalidMetadataHash();

        rightId = _nextRightId++;

        RightStatus initialStatus = params.activateImmediately ? RightStatus.Active : RightStatus.Issued;
        address controller = params.controller == address(0) ? params.to : params.controller;
        uint32 lineageFlags = params.lineageFlags == 0 ? LINEAGE_ORIGINAL_ISSUANCE : params.lineageFlags;

        _rights[rightId] = RightRecord({
            issuerId: params.issuerId,
            resourceUnit: params.resourceUnit,
            lifecycleStatus: initialStatus,
            freezeReason: FreezeReason.None,
            lineageFlags: lineageFlags,
            maxAmount: params.maxAmount,
            remainingAmount: params.initialRemainingAmount,
            windowStart: params.windowStart,
            windowEnd: params.windowEnd,
            parentRightId: params.parentRightId,
            metadataHash: params.metadataHash,
            finalizationRef: bytes32(0),
            controller: controller
        });

        _metadataURIs[rightId] = params.metadataURI;
        _safeMint(params.to, rightId);

        emit RightIssued(rightId, params.issuerId, params.to, params.metadataHash, params.maxAmount, params.initialRemainingAmount);
        if (initialStatus == RightStatus.Active) {
            emit RightActivated(rightId);
        }
    }

    function activateRight(uint256 rightId) external onlyRole(ISSUER_ROLE) {
        RightRecord storage right = _requireRight(rightId);
        if (right.lifecycleStatus != RightStatus.Issued) revert InvalidStatus(right.lifecycleStatus);
        _setStatus(rightId, right, RightStatus.Active);
        emit RightActivated(rightId);
    }

    function consumeRight(ConsumeRightParams calldata params) external onlyRole(CONSUMER_ROLE) {
        RightRecord storage right = _requireRight(params.rightId);
        if (right.lifecycleStatus != RightStatus.Active) revert InvalidStatus(right.lifecycleStatus);
        if (params.amount == 0 || params.amount > right.remainingAmount) revert InvalidAmount();
        if (params.settlementRef == bytes32(0)) revert InvalidSettlementRef();

        right.remainingAmount -= params.amount;
        if (right.remainingAmount == 0) {
            _setStatus(params.rightId, right, RightStatus.FullyConsumed);
        }

        emit RightConsumed(params.rightId, params.amount, right.remainingAmount, params.settlementRef);
    }

    function splitRight(SplitRightParams calldata params)
        external
        onlyRole(ISSUER_ROLE)
        returns (uint256[] memory childRightIds)
    {
        RightRecord storage parent = _requireRight(params.parentRightId);
        if (parent.lifecycleStatus != RightStatus.Active) revert InvalidStatus(parent.lifecycleStatus);

        uint256 count = params.recipients.length;
        if (
            count == 0 ||
            count != params.amounts.length ||
            count != params.childMetadataHashes.length ||
            count != params.childMetadataURIs.length
        ) revert SplitArrayLengthMismatch();

        childRightIds = new uint256[](count);
        uint256 total;

        for (uint256 i = 0; i < count; i++) {
            if (params.recipients[i] == address(0)) revert ZeroAddress();
            if (params.amounts[i] == 0) revert InvalidAmount();
            if (params.childMetadataHashes[i] == bytes32(0)) revert InvalidMetadataHash();
            total += params.amounts[i];
        }

        if (total > parent.remainingAmount) revert SplitAmountExceeded();

        parent.remainingAmount -= uint128(total);
        if (parent.remainingAmount == 0) {
            _setStatus(params.parentRightId, parent, RightStatus.FullyConsumed);
        }

        for (uint256 i = 0; i < count; i++) {
            uint256 childRightId = _nextRightId++;
            childRightIds[i] = childRightId;

            _rights[childRightId] = RightRecord({
                issuerId: parent.issuerId,
                resourceUnit: parent.resourceUnit,
                lifecycleStatus: RightStatus.Active,
                freezeReason: FreezeReason.None,
                lineageFlags: LINEAGE_SPLIT_CHILD,
                maxAmount: params.amounts[i],
                remainingAmount: params.amounts[i],
                windowStart: parent.windowStart,
                windowEnd: parent.windowEnd,
                parentRightId: params.parentRightId,
                metadataHash: params.childMetadataHashes[i],
                finalizationRef: bytes32(0),
                controller: params.recipients[i]
            });

            _metadataURIs[childRightId] = params.childMetadataURIs[i];
            _safeMint(params.recipients[i], childRightId);

            emit RightIssued(
                childRightId,
                parent.issuerId,
                params.recipients[i],
                params.childMetadataHashes[i],
                params.amounts[i],
                params.amounts[i]
            );
            emit RightSplit(params.parentRightId, childRightId, params.recipients[i], params.amounts[i]);
        }
    }

    function freezeRight(uint256 rightId, FreezeReason reason) external onlyRole(FREEZER_ROLE) {
        if (reason == FreezeReason.None) revert FreezeReasonRequired();
        RightRecord storage right = _requireRight(rightId);
        RightStatus current = right.lifecycleStatus;
        if (current == RightStatus.Burned || current == RightStatus.Finalized) revert InvalidStatus(current);
        right.freezeReason = reason;
        _setStatus(rightId, right, RightStatus.Frozen);
        emit RightFrozen(rightId, reason);
    }

    function unfreezeRight(uint256 rightId) external onlyRole(FREEZER_ROLE) {
        RightRecord storage right = _requireRight(rightId);
        if (right.lifecycleStatus != RightStatus.Frozen) revert InvalidStatus(right.lifecycleStatus);
        right.freezeReason = FreezeReason.None;
        _setStatus(rightId, right, _derivePostFreezeStatus(right));
        emit RightUnfrozen(rightId);
    }

    function expireRight(uint256 rightId) external {
        RightRecord storage right = _requireRight(rightId);
        RightStatus current = right.lifecycleStatus;
        if (current != RightStatus.Issued && current != RightStatus.Active && current != RightStatus.Frozen) {
            revert InvalidStatus(current);
        }
        if (block.timestamp < right.windowEnd) revert InvalidWindow();
        right.freezeReason = FreezeReason.None;
        _setStatus(rightId, right, RightStatus.Expired);
    }

    function finalizeRight(uint256 rightId, bytes32 finalizationRef) external onlyRole(FINALIZER_ROLE) {
        if (finalizationRef == bytes32(0)) revert InvalidSettlementRef();
        RightRecord storage right = _requireRight(rightId);
        if (right.lifecycleStatus == RightStatus.Burned) revert InvalidStatus(right.lifecycleStatus);
        right.finalizationRef = finalizationRef;
        _setStatus(rightId, right, RightStatus.Finalized);
        emit RightFinalized(rightId, finalizationRef);
    }

    function burnRight(uint256 rightId) external onlyRole(BURNER_ROLE) {
        RightRecord storage right = _requireRight(rightId);
        _setStatus(rightId, right, RightStatus.Burned);
        _burn(rightId);
    }

    function setController(uint256 rightId, address newController) external {
        if (newController == address(0)) revert ZeroAddress();
        _checkAuthorized(_ownerOf(rightId), msg.sender, rightId);

        RightRecord storage right = _requireRight(rightId);
        address oldController = right.controller;
        right.controller = newController;
        emit RightControllerUpdated(rightId, oldController, newController);
    }

    function getRight(uint256 rightId) external view returns (RightRecord memory) {
        return _requireRightView(rightId);
    }

    function remainingAmount(uint256 rightId) external view returns (uint128) {
        return _requireRightView(rightId).remainingAmount;
    }

    function maxAmount(uint256 rightId) external view returns (uint128) {
        return _requireRightView(rightId).maxAmount;
    }

    function lifecycleStatus(uint256 rightId) external view returns (RightStatus) {
        return _requireRightView(rightId).lifecycleStatus;
    }

    function freezeReasonOf(uint256 rightId) external view returns (FreezeReason) {
        return _requireRightView(rightId).freezeReason;
    }

    function controllerOf(uint256 rightId) external view returns (address) {
        return _requireRightView(rightId).controller;
    }

    function metadataHashOf(uint256 rightId) external view returns (bytes32) {
        return _requireRightView(rightId).metadataHash;
    }

    function metadataURIOf(uint256 rightId) external view returns (string memory) {
        _requireOwned(rightId);
        return _metadataURIs[rightId];
    }

    function parentRightOf(uint256 rightId) external view returns (uint256) {
        return _requireRightView(rightId).parentRightId;
    }

    function finalizationRefOf(uint256 rightId) external view returns (bytes32) {
        return _requireRightView(rightId).finalizationRef;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address from) {
        from = _ownerOf(tokenId);

        if (from != address(0)) {
            _enforceTransferable(_rights[tokenId].lifecycleStatus);
        }

        return super._update(to, tokenId, auth);
    }

    function _requireOwned(uint256 rightId) internal view returns (address owner) {
        owner = _ownerOf(rightId);
        if (owner == address(0)) revert RightDoesNotExist(rightId);
    }

    function _requireRight(uint256 rightId) internal view returns (RightRecord storage right) {
        _requireOwned(rightId);
        right = _rights[rightId];
    }

    function _requireRightView(uint256 rightId) internal view returns (RightRecord memory right) {
        _requireOwned(rightId);
        right = _rights[rightId];
    }

    function _setStatus(uint256 rightId, RightRecord storage right, RightStatus nextStatus) internal {
        RightStatus oldStatus = right.lifecycleStatus;
        if (oldStatus == nextStatus) return;
        right.lifecycleStatus = nextStatus;
        emit RightStatusChanged(rightId, oldStatus, nextStatus);
    }

    function _derivePostFreezeStatus(RightRecord storage right) internal view returns (RightStatus) {
        if (block.timestamp >= right.windowEnd) {
            return RightStatus.Expired;
        }
        if (right.remainingAmount == 0) {
            return RightStatus.FullyConsumed;
        }
        return RightStatus.Active;
    }

    function _enforceTransferable(RightStatus status) internal pure {
        if (
            status == RightStatus.Frozen ||
            status == RightStatus.Finalized ||
            status == RightStatus.Burned
        ) {
            revert TransferBlocked(status);
        }
    }
}
