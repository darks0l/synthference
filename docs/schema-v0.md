# Synthference Schema v0

## Goal

Define a portable, machine-readable envelope for a **synthetic inference right**.

A Synthference right is a bounded claim on future compute capacity with explicit execution constraints, fallback behavior, and settlement outcomes.

---

## Design principles

1. **Portable** - not locked to one provider or network
2. **Bounded** - no hidden infinite service liability
3. **Time-scoped** - every right has a usable window
4. **Policy-aware** - routing and fallback are explicit
5. **Settlement-first** - fulfillment outcomes are modeled directly
6. **Agent-native** - easy for agents and apps to reason about programmatically

---

## Core object

```json
{
  "rightId": "sr_01...",
  "version": "synthference/v0",
  "kind": "reserved|burst|background|custom",
  "resource": {},
  "service": {},
  "window": {},
  "limits": {},
  "fallbackPolicy": {},
  "settlementPolicy": {},
  "issuer": {},
  "holder": {},
  "routingHints": {},
  "metadata": {}
}
```

---

## Field definitions

### `rightId`
Unique identifier for the position/right.

### `version`
Schema version tag.

### `kind`
High-level shape of the right.

Options:
- `reserved` - predictable reserved access
- `burst` - high-priority elastic access in a limited window
- `background` - low-priority deferred execution
- `custom` - nonstandard structured right

---

## `resource`
Describes the compute unit being claimed.

```json
{
  "type": "text_inference|image_generation|video_generation|embeddings|agent_runtime|gpu_time|custom",
  "unit": "tokens|requests|jobs|frames|seconds|minutes",
  "amount": 1000000,
  "modelClass": ["reasoning", "chat", "image", "video"],
  "capabilityTags": ["tool-use", "json-mode", "vision"]
}
```

### Notes
- `type` describes the service family
- `unit` describes how the right is consumed
- `amount` is the maximum deliverable quantity
- `modelClass` keeps the schema provider-agnostic
- `capabilityTags` lets rights express execution requirements without hardcoding brands

---

## `service`
Defines quality, latency, privacy, and execution constraints.

```json
{
  "priority": "premium|standard|background",
  "latencyClass": "realtime|interactive|batch",
  "privacyClass": "public|private|confidential|local-only",
  "jurisdiction": ["any", "us", "eu"],
  "providerConstraints": {
    "allow": [],
    "deny": []
  }
}
```

### Notes
- `priority` affects routing preference and fallback behavior
- `latencyClass` defines expectation, not absolute guarantee
- `privacyClass` matters a lot for enterprise or local-node execution
- `providerConstraints` allows policy-based inclusion/exclusion

---

## `window`
Defines when the right may be used.

```json
{
  "start": "2026-06-12T00:00:00Z",
  "end": "2026-06-19T00:00:00Z",
  "mode": "fixed|rolling|epoch",
  "epochSizeSeconds": 3600
}
```

### Modes
- `fixed` - explicit start/end range
- `rolling` - right rolls forward from activation
- `epoch` - usage resets or settles on repeating intervals

---

## `limits`
Controls usage boundaries.

```json
{
  "maxPerRequest": 50000,
  "maxConcurrent": 10,
  "maxBurst": 100000,
  "rateLimitPerMinute": 200,
  "partialFillAllowed": true
}
```

### Notes
These limits prevent implicit over-promising and help suppliers publish usable inventory.

---

## `fallbackPolicy`
Defines acceptable degradation behavior.

```json
{
  "allowFallback": true,
  "substituteModelClass": ["chat", "reasoning"],
  "substituteProviders": true,
  "downgradePriority": true,
  "downgradeLatencyClass": true,
  "deferWithinWindow": true,
  "maxQualityLossBps": 1500,
  "maxLatencyExpansionBps": 3000
}
```

### Notes
This is one of the core Synthference ideas.
The right is not binary fulfilled/failed only; it can settle through bounded fallback lanes.

---

## `settlementPolicy`
Defines how outcomes are recognized.

```json
{
  "successStates": ["full", "fallback", "partial"],
  "failureStates": ["failed", "expired"],
  "proofRequirements": ["usage-meter", "completion-log"],
  "refundPolicy": "none|pro-rata|credit-reissue|custom",
  "disputeWindowSeconds": 86400
}
```

### Settlement states
- `full` - delivered within requested envelope
- `fallback` - delivered via allowed substitute path
- `partial` - partially consumed or partially satisfied
- `failed` - execution attempt did not satisfy policy
- `expired` - window elapsed before valid usage

---

## `issuer`
Defines who originated the right.

```json
{
  "issuerType": "provider|market|coordinator|vault|protocol",
  "issuerId": "mesh_alpha",
  "attestations": ["capacity-posted", "stake-bonded"]
}
```

---

## `holder`
Defines who controls the right.

```json
{
  "holderType": "user|agent|app|vault|market-maker",
  "holderId": "agent_123"
}
```

---

## `routingHints`
Optional execution preferences for routers.

```json
{
  "preferredProviders": ["provider_a", "provider_b"],
  "preferredRegions": ["us-east", "eu-west"],
  "costWeight": 0.5,
  "latencyWeight": 0.3,
  "privacyWeight": 0.2
}
```

### Notes
Hints guide execution but should not override hard policy constraints.

---

## `metadata`
Freeform descriptive data.

```json
{
  "label": "premium weekend launch capacity",
  "description": "burst capacity for a public release",
  "tags": ["launch", "agent", "priority"]
}
```

---

## Example right

```json
{
  "rightId": "sr_01jxyz",
  "version": "synthference/v0",
  "kind": "burst",
  "resource": {
    "type": "text_inference",
    "unit": "tokens",
    "amount": 2000000,
    "modelClass": ["chat", "reasoning"],
    "capabilityTags": ["tool-use", "json-mode"]
  },
  "service": {
    "priority": "premium",
    "latencyClass": "interactive",
    "privacyClass": "private",
    "jurisdiction": ["us", "eu"],
    "providerConstraints": { "allow": [], "deny": [] }
  },
  "window": {
    "start": "2026-06-14T00:00:00Z",
    "end": "2026-06-16T00:00:00Z",
    "mode": "fixed",
    "epochSizeSeconds": 0
  },
  "limits": {
    "maxPerRequest": 20000,
    "maxConcurrent": 20,
    "maxBurst": 250000,
    "rateLimitPerMinute": 400,
    "partialFillAllowed": true
  },
  "fallbackPolicy": {
    "allowFallback": true,
    "substituteModelClass": ["chat"],
    "substituteProviders": true,
    "downgradePriority": false,
    "downgradeLatencyClass": true,
    "deferWithinWindow": true,
    "maxQualityLossBps": 1000,
    "maxLatencyExpansionBps": 2500
  },
  "settlementPolicy": {
    "successStates": ["full", "fallback", "partial"],
    "failureStates": ["failed", "expired"],
    "proofRequirements": ["usage-meter", "completion-log"],
    "refundPolicy": "pro-rata",
    "disputeWindowSeconds": 86400
  },
  "issuer": {
    "issuerType": "protocol",
    "issuerId": "synthference-core",
    "attestations": ["capacity-posted"]
  },
  "holder": {
    "holderType": "agent",
    "holderId": "agent_ops_7"
  },
  "routingHints": {
    "preferredProviders": ["pool_a"],
    "preferredRegions": ["us-east"],
    "costWeight": 0.2,
    "latencyWeight": 0.5,
    "privacyWeight": 0.3
  },
  "metadata": {
    "label": "launch-weekend premium text",
    "description": "premium burst capacity for release traffic",
    "tags": ["launch", "premium", "text"]
  }
}
```

---

## Open questions

- Should model capability be taxonomy-first or vendor-first?
- How should proof formats be normalized across centralized and decentralized suppliers?
- Should rights be fungible by class or always position-specific?
- Where should dispute logic live: offchain coordinator, onchain registry, or bilateral attestation?
- How should rolling rights be reissued or netted at settlement boundaries?
