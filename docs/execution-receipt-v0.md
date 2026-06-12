# Synthference Execution Receipt v0

## Goal

Define the normalized post-execution object that records **what actually happened** when a Synthference request was routed and executed.

If the request envelope is the invocation object, the execution receipt is the canonical outcome object that feeds settlement.

---

## Design principles

1. **Outcome-first** - describe what was delivered, not just that a call happened
2. **Settlement-ready** - enough structure to classify `full`, `fallback`, `partial`, `failed`, or `expired`
3. **Provider-agnostic** - unify heterogeneous execution backends
4. **Proof-friendly** - attach evidence without forcing one proof format
5. **Split-route aware** - support one receipt with one or many execution legs
6. **Human-auditable** - clear enough for ops, dispute review, and agent introspection

---

## Core object

```json
{
  "receiptId": "rcpt_01...",
  "version": "synthference-receipt/v0",
  "requestId": "req_01...",
  "status": "completed|fallback_completed|partially_completed|failed|expired|deferred|cancelled",
  "holder": {},
  "rightsConsumed": [],
  "executionSummary": {},
  "executionLegs": [],
  "usage": {},
  "delivery": {},
  "proofs": [],
  "timestamps": {},
  "metadata": {}
}
```

---

## Field definitions

### `receiptId`
Unique receipt identifier.

### `version`
Schema version for the receipt object.

### `requestId`
Reference to the originating request envelope.

### `status`
Top-level outcome state.

Allowed values:
- `completed`
- `fallback_completed`
- `partially_completed`
- `failed`
- `expired`
- `deferred`
- `cancelled`

---

## `holder`
The consuming party.

```json
{
  "holderType": "user|agent|app|vault|market-maker",
  "holderId": "agent_ops_7"
}
```

---

## `rightsConsumed`
Describes how one or more rights were actually spent.

```json
[
  {
    "rightId": "sr_01jxyz",
    "consumedUnits": {
      "unit": "tokens",
      "amount": 11842
    },
    "reservedUnits": {
      "unit": "tokens",
      "amount": 15000
    },
    "settlementImpact": "full|fallback|partial|none",
    "remainingBalanceEstimate": {
      "unit": "tokens",
      "amount": 1988158
    }
  }
]
```

### Notes
This is pre-final-settlement usage reporting, but it should be close enough to drive settlement deterministically.

---

## `executionSummary`
High-level classification of the result.

```json
{
  "resourceType": "text_inference",
  "operation": "generate",
  "resultShape": "json",
  "fulfillmentMode": "full|fallback|partial|none",
  "usedFallback": false,
  "usedSplitRoute": false,
  "deferred": false,
  "finalSupplierCount": 1,
  "policyCompliance": "within_bounds|bounded_degradation|out_of_bounds"
}
```

### Notes
This is the bridge between execution and settlement semantics.

---

## `executionLegs`
Detailed per-route execution records.

```json
[
  {
    "legId": "leg_01a",
    "supplierId": "pool_a",
    "providerType": "centralized-api|decentralized-network|local-cluster|private-gateway|custom",
    "region": "us-east",
    "modelClass": "chat",
    "capabilityTags": ["tool-use", "json-mode"],
    "status": "completed|fallback_completed|partially_completed|failed|skipped",
    "fallbackApplied": false,
    "latencyMs": 2150,
    "startedAt": "2026-06-14T14:58:01Z",
    "completedAt": "2026-06-14T14:58:03Z",
    "outputRef": "artifact://result_123",
    "errorCode": null,
    "errorMessage": null
  }
]
```

### Notes
- one receipt may contain multiple legs
- useful for split-route and fallback scenarios
- `outputRef` can point to a payload, artifact store, or signed result blob

---

## `usage`
Normalized usage and performance reporting.

```json
{
  "billableUnits": {
    "unit": "tokens",
    "amount": 11842
  },
  "deliveredUnits": {
    "unit": "tokens",
    "amount": 11842
  },
  "latencyMs": 2150,
  "queueDelayMs": 340,
  "computeTimeMs": 1810,
  "qualityScore": 0.94
}
```

### Notes
Not every backend exposes all metrics. Missing fields can be null or omitted if normalization rules allow it.

---

## `delivery`
Describes what happened to the result artifact.

```json
{
  "mode": "sync|async|webhook|queue|artifact",
  "target": "session://workflow_123",
  "delivered": true,
  "deliveredAt": "2026-06-14T14:58:04Z",
  "deliveryRef": "delivery://abc123"
}
```

---

## `proofs`
Attached or referenced evidence.

```json
[
  {
    "type": "usage-meter|completion-log|latency-attestation|supplier-signature|artifact-hash|custom",
    "ref": "proof://meter_456",
    "hash": "sha256:...",
    "issuer": "pool_a"
  }
]
```

### Notes
Proofs should be referenceable and hashable even if the full proof body lives elsewhere.

---

## `timestamps`
Lifecycle timing for the receipt itself.

```json
{
  "receivedAt": "2026-06-14T14:58:00Z",
  "matchedAt": "2026-06-14T14:58:00Z",
  "executionStartedAt": "2026-06-14T14:58:01Z",
  "executionCompletedAt": "2026-06-14T14:58:03Z",
  "receiptIssuedAt": "2026-06-14T14:58:03Z"
}
```

---

## `metadata`
Freeform annotations.

```json
{
  "label": "launch-json-run-receipt",
  "tags": ["ops", "priority"],
  "notes": "single-route completion within premium bounds"
}
```

---

## Example receipt

```json
{
  "receiptId": "rcpt_01k999",
  "version": "synthference-receipt/v0",
  "requestId": "req_01k123",
  "status": "completed",
  "holder": {
    "holderType": "agent",
    "holderId": "agent_ops_7"
  },
  "rightsConsumed": [
    {
      "rightId": "sr_01jxyz",
      "consumedUnits": {
        "unit": "tokens",
        "amount": 11842
      },
      "reservedUnits": {
        "unit": "tokens",
        "amount": 15000
      },
      "settlementImpact": "full",
      "remainingBalanceEstimate": {
        "unit": "tokens",
        "amount": 1988158
      }
    }
  ],
  "executionSummary": {
    "resourceType": "text_inference",
    "operation": "generate",
    "resultShape": "json",
    "fulfillmentMode": "full",
    "usedFallback": false,
    "usedSplitRoute": false,
    "deferred": false,
    "finalSupplierCount": 1,
    "policyCompliance": "within_bounds"
  },
  "executionLegs": [
    {
      "legId": "leg_01a",
      "supplierId": "pool_a",
      "providerType": "centralized-api",
      "region": "us-east",
      "modelClass": "chat",
      "capabilityTags": ["tool-use", "json-mode"],
      "status": "completed",
      "fallbackApplied": false,
      "latencyMs": 2150,
      "startedAt": "2026-06-14T14:58:01Z",
      "completedAt": "2026-06-14T14:58:03Z",
      "outputRef": "artifact://result_123",
      "errorCode": null,
      "errorMessage": null
    }
  ],
  "usage": {
    "billableUnits": {
      "unit": "tokens",
      "amount": 11842
    },
    "deliveredUnits": {
      "unit": "tokens",
      "amount": 11842
    },
    "latencyMs": 2150,
    "queueDelayMs": 340,
    "computeTimeMs": 1810,
    "qualityScore": 0.94
  },
  "delivery": {
    "mode": "async",
    "target": "session://workflow_123",
    "delivered": true,
    "deliveredAt": "2026-06-14T14:58:04Z",
    "deliveryRef": "delivery://abc123"
  },
  "proofs": [
    {
      "type": "usage-meter",
      "ref": "proof://meter_456",
      "hash": "sha256:abc123",
      "issuer": "pool_a"
    },
    {
      "type": "artifact-hash",
      "ref": "artifact://result_123",
      "hash": "sha256:def456",
      "issuer": "router_1"
    }
  ],
  "timestamps": {
    "receivedAt": "2026-06-14T14:58:00Z",
    "matchedAt": "2026-06-14T14:58:00Z",
    "executionStartedAt": "2026-06-14T14:58:01Z",
    "executionCompletedAt": "2026-06-14T14:58:03Z",
    "receiptIssuedAt": "2026-06-14T14:58:03Z"
  },
  "metadata": {
    "label": "launch-json-run-receipt",
    "tags": ["ops", "priority"],
    "notes": "single-route completion within premium bounds"
  }
}
```

---

## Validation / classification rules

At minimum, settlement systems should be able to infer:

- whether any right was actually consumed
- whether fallback occurred
- whether execution stayed within allowed policy bounds
- whether partial completion happened
- whether request deadline/window was missed
- whether outputs were delivered
- whether attached proofs satisfy minimum settlement requirements

---

## Relationship to settlement

The receipt should be sufficient for a settlement engine to compute:

- right balance deltas
- success vs fallback vs partial classification
- refund or reissue triggers
- supplier credit/payment triggers
- dispute eligibility windows

That means the receipt is not the final ledger state, but it is the canonical **input** to final ledger state.

---

## Open questions

- Should receipts be append-only with amendments, or replaceable until settlement finalization?
- Should split-route receipts support nested child receipts?
- How should quality be normalized across heterogeneous model/provider types?
- Which proof types are mandatory for each resource class?
- Should delivery failure create a failed receipt, or a completed-but-undelivered receipt state?
