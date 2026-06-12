# Synthference Request Envelope v0

## Goal

Define the execution-time object that **consumes or attempts to consume** a Synthference right.

If `schema-v0` defines **what a right is**, the request envelope defines **how a holder invokes it**.
The resulting execution should produce an [Execution Receipt v0](./execution-receipt-v0.md) object for settlement.

---

## Design principles

1. **Explicit intent** - request describes desired work, not just raw usage
2. **Right-aware** - request references one or more usable rights
3. **Policy-bounded** - request cannot silently exceed right constraints
4. **Router-friendly** - request gives enough structure for matching and fallback
5. **Settlement-ready** - request creates a clean audit trail for outcome classification
6. **Composable** - supports single-route, split-route, and deferred execution

---

## Core object

```json
{
  "requestId": "req_01...",
  "version": "synthference-request/v0",
  "holder": {},
  "intent": {},
  "rights": [],
  "constraints": {},
  "executionPreferences": {},
  "fallbackRequestPolicy": {},
  "budgetPolicy": {},
  "delivery": {},
  "metadata": {}
}
```

---

## Field definitions

### `requestId`
Unique request identifier.

### `version`
Schema version for the request envelope.

---

## `holder`
The party invoking execution.

```json
{
  "holderType": "user|agent|app|vault|market-maker",
  "holderId": "agent_ops_7",
  "actingAs": "end-user|autonomous-agent|workflow|system"
}
```

### Notes
This may match the right holder exactly, or reflect an authorized actor operating on behalf of a holder.

---

## `intent`
Describes the actual work to be executed.

```json
{
  "resourceType": "text_inference|image_generation|video_generation|embeddings|agent_runtime|gpu_time|custom",
  "operation": "generate|embed|classify|transcribe|tool-run|workflow|custom",
  "payloadRef": "payload_abc123",
  "expectedUnits": {
    "unit": "tokens|requests|jobs|frames|seconds|minutes",
    "amount": 12000
  },
  "capabilityRequirements": ["tool-use", "json-mode"],
  "resultShape": "text|json|image|video|embedding|artifact|custom"
}
```

### Notes
- `payloadRef` points to the actual prompt/workload or external payload descriptor
- the protocol does not need to inline sensitive prompt content in the request object itself
- `expectedUnits` is a planning estimate, not necessarily final usage

---

## `rights`
References the rights the requester wants to use.

```json
[
  {
    "rightId": "sr_01jxyz",
    "priority": 1,
    "maxSpend": {
      "unit": "tokens",
      "amount": 15000
    }
  }
]
```

### Notes
- supports one or many candidate rights
- `priority` lets the holder express ordering
- `maxSpend` prevents accidental over-consumption of a right

---

## `constraints`
Hard execution requirements that must be satisfied.

```json
{
  "latestCompletionAt": "2026-06-14T15:00:00Z",
  "privacyClass": "private",
  "jurisdiction": ["us", "eu"],
  "maxLatencyMs": 4000,
  "minCapabilityTags": ["json-mode"],
  "providerConstraints": {
    "allow": [],
    "deny": []
  },
  "mustRemainWithinRightWindow": true
}
```

### Notes
These are hard guards. If they cannot be met, the request should fail or defer rather than silently degrade beyond policy.

---

## `executionPreferences`
Soft routing preferences.

```json
{
  "preferredProviders": ["pool_a", "pool_b"],
  "preferredRegions": ["us-east"],
  "preferSingleRoute": true,
  "allowSplitExecution": false,
  "allowDeferredExecution": true,
  "costWeight": 0.2,
  "latencyWeight": 0.5,
  "qualityWeight": 0.2,
  "privacyWeight": 0.1
}
```

### Notes
These guide the router but should not override the right or hard constraints.

---

## `fallbackRequestPolicy`
Request-scoped degradation rules.

```json
{
  "allowFallback": true,
  "allowAlternativeRight": true,
  "allowAlternativeProvider": true,
  "allowModelClassDowngrade": false,
  "allowLatencyDowngrade": true,
  "allowDeferredCompletion": true,
  "maxDeferralSeconds": 1800,
  "maxPartialFill": 0.5
}
```

### Notes
This layers on top of the underlying right's `fallbackPolicy`.
The effective fallback set should be the **intersection** of the right policy and request policy.

---

## `budgetPolicy`
Controls budget and charging behavior.

```json
{
  "maxBillableUnits": {
    "unit": "tokens",
    "amount": 15000
  },
  "allowTopUp": false,
  "allowCrossRightSpillover": true,
  "chargeMode": "actual|reserved-draw|quoted-cap"
}
```

### Notes
This matters when requests may span multiple rights or when actual consumption differs from planned consumption.

---

## `delivery`
Describes how results should be returned.

```json
{
  "mode": "sync|async|webhook|queue|artifact",
  "target": "session://abc123",
  "deadline": "2026-06-14T15:00:00Z",
  "includeExecutionReceipt": true
}
```

### Notes
The delivery mode should shape how the router thinks about deferral and execution windows.

---

## `metadata`
Freeform request annotations.

```json
{
  "label": "launch-day premium completion",
  "description": "high-priority JSON generation for operator workflow",
  "tags": ["launch", "json", "priority"]
}
```

---

## Request lifecycle

A request should move through a clear state path:

1. `received`
2. `validated`
3. `matched`
4. `executing`
5. `completed|fallback_completed|partially_completed|failed|expired|deferred`
6. `settled`

Optional side states:
- `disputed`
- `cancelled`
- `superseded`

---

## Example request

```json
{
  "requestId": "req_01k123",
  "version": "synthference-request/v0",
  "holder": {
    "holderType": "agent",
    "holderId": "agent_ops_7",
    "actingAs": "workflow"
  },
  "intent": {
    "resourceType": "text_inference",
    "operation": "generate",
    "payloadRef": "payload_abc123",
    "expectedUnits": {
      "unit": "tokens",
      "amount": 12000
    },
    "capabilityRequirements": ["tool-use", "json-mode"],
    "resultShape": "json"
  },
  "rights": [
    {
      "rightId": "sr_01jxyz",
      "priority": 1,
      "maxSpend": {
        "unit": "tokens",
        "amount": 15000
      }
    }
  ],
  "constraints": {
    "latestCompletionAt": "2026-06-14T15:00:00Z",
    "privacyClass": "private",
    "jurisdiction": ["us"],
    "maxLatencyMs": 4000,
    "minCapabilityTags": ["json-mode"],
    "providerConstraints": {
      "allow": [],
      "deny": []
    },
    "mustRemainWithinRightWindow": true
  },
  "executionPreferences": {
    "preferredProviders": ["pool_a"],
    "preferredRegions": ["us-east"],
    "preferSingleRoute": true,
    "allowSplitExecution": false,
    "allowDeferredExecution": true,
    "costWeight": 0.2,
    "latencyWeight": 0.5,
    "qualityWeight": 0.2,
    "privacyWeight": 0.1
  },
  "fallbackRequestPolicy": {
    "allowFallback": true,
    "allowAlternativeRight": true,
    "allowAlternativeProvider": true,
    "allowModelClassDowngrade": false,
    "allowLatencyDowngrade": true,
    "allowDeferredCompletion": true,
    "maxDeferralSeconds": 900,
    "maxPartialFill": 0.25
  },
  "budgetPolicy": {
    "maxBillableUnits": {
      "unit": "tokens",
      "amount": 15000
    },
    "allowTopUp": false,
    "allowCrossRightSpillover": true,
    "chargeMode": "actual"
  },
  "delivery": {
    "mode": "async",
    "target": "session://workflow_123",
    "deadline": "2026-06-14T15:00:00Z",
    "includeExecutionReceipt": true
  },
  "metadata": {
    "label": "operator-json-run",
    "description": "priority workflow generation",
    "tags": ["ops", "json", "priority"]
  }
}
```

---

## Validation rules

At minimum, routers or coordinators should validate:

- referenced rights exist and are active
- holder is authorized to spend the rights
- request resource type fits right resource type
- expected units do not exceed `maxSpend`
- request window fits within right window
- request constraints do not exceed right service constraints
- effective fallback policy is non-empty if fallback is expected
- budget policy is compatible with execution mode

---

## Effective policy model

The effective execution policy should be computed as:

- **hard constraints** = intersection of:
  - right policy
  - request constraints
  - supplier constraints

- **fallback permissions** = intersection of:
  - right fallback policy
  - request fallback policy

- **routing optimization** = weighted preferences from:
  - request execution preferences
  - right routing hints
  - coordinator defaults

This is important because it gives agents and apps local control without letting them exceed the bound of the right they actually hold.

---

## Settlement handoff

A validated and executed request should emit exactly one canonical receipt object, even if execution spans multiple internal supplier legs. That receipt is the normalized handoff into settlement.

---

## Open questions

- Should requests reference one right, many rights, or an abstract right class by default?
- How should multi-step agent workflows consume rights across sub-actions?
- Should payload references be opaque by default for privacy-preserving routes?
- When should routers auto-split execution across suppliers versus fail closed?
- Should deferred requests create a new reserving artifact or stay as open execution intents?
