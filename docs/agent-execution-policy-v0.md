# Synthference Agent Execution Policy v0

## Goal

Define how Synthference routing decisions become concrete, agent-native execution behavior.

This document sits between the routing layer and the execution adapter layer.
It explains how an agent, workflow runtime, or coordinator should interpret a selected route, enforce policy, and emit normalized execution outcomes.

---

## Why this layer matters

A router can choose a valid route on paper and still fail operationally if the execution runtime does not know:
- what constraints are hard versus soft
- when fallback is still allowed
- when deferral is allowed
- when partial completion is acceptable
- when to abort rather than continue
- what evidence must be recorded during execution

Without an execution policy layer, Synthference risks stopping at matching logic instead of becoming a usable runtime primitive.

---

## Core idea

A routed request should produce an **execution policy envelope** that an agent or runtime can actually follow.

That envelope should tell the runtime:
- what it is allowed to do
- what it must not do
- what it should try first
- what alternate paths are allowed
- what proof artifacts it must preserve
- what should happen when execution deviates from plan

---

## Design principles

1. **Hard guards stay hard** - the runtime must not silently violate right or request constraints
2. **Fallback must be explicit** - allowed degradation should be machine-readable
3. **Execution remains local and practical** - policy should guide real runtimes, not idealized ones
4. **Proof preservation is first-class** - execution policy should name required evidence outputs
5. **Aborts are valid outcomes** - safe refusal is better than invalid fulfillment

---

## Policy chain

Execution policy is derived from multiple layers.

### 1. Right policy
Comes from the right itself.
Examples:
- privacy class
- latency class
- fallback bounds
- settlement proof requirements

### 2. Request policy
Comes from the invocation.
Examples:
- latest completion time
- max partial fill
- preferred regions
- request-specific fallback tightening

### 3. Route policy
Comes from the chosen route.
Examples:
- selected supplier
- locked resource slice
- deferral window
- route expiry time

### 4. Runtime policy
Comes from the executing system.
Examples:
- local secret handling rules
- tool permissions
- allowed network egress
- operator approval gates

### Effective rule
The runtime should obey the **intersection** of these policies, not the loosest combination.

---

## Execution policy envelope

A route selection should compile into a normalized execution policy object.

```json
{
  "executionPolicyId": "execpol_01",
  "requestId": "req_01",
  "rightRefs": ["sr_01"],
  "routeRef": "route_01",
  "hardConstraints": {
    "privacyClass": "private",
    "latestCompletionAt": "2026-06-12T01:00:00Z",
    "mustRemainWithinRightWindow": true,
    "allowedProviders": ["provider_a"],
    "forbiddenFallbacks": ["privacy-downgrade"]
  },
  "allowedFallbacks": {
    "providerSwap": true,
    "latencyDowngrade": false,
    "qualityDowngrade": true,
    "deferral": true,
    "partialCompletion": false
  },
  "proofRequirements": {
    "profile": "standard",
    "requiredProofTypes": [
      "route-lock-record",
      "execution-log",
      "usage-meter",
      "output-reference"
    ]
  },
  "runtimeControls": {
    "requireApprovalForOffPolicy": true,
    "abortOnConstraintViolation": true,
    "preserveIntermediateLogs": true
  }
}
```

---

## Runtime responsibilities

An agent or workflow runtime should be responsible for:

1. loading the effective execution policy
2. validating the runtime can satisfy it
3. executing against the selected route
4. refusing or aborting if hard constraints cannot be honored
5. preserving required proof artifacts
6. emitting a normalized outcome object for settlement

---

## Hard constraints vs soft preferences

### Hard constraints
If violated, the runtime should fail, defer, or seek a new route.

Examples:
- privacy requirement
- jurisdiction limit
- latest completion bound
- route lock expiry
- explicit provider deny rule
- disallowed model class downgrade

### Soft preferences
The runtime may optimize around these, but not violate hard policy to satisfy them.

Examples:
- lower cost preference
- preferred region
- preferred single-route fill
- preferred premium path when equivalent options exist

---

## Execution decision points

A runtime should have explicit decision points.

### 1. Preflight
Before starting, verify:
- route lock is still valid
- required supplier/adapter is reachable
- required tool/network permissions exist
- runtime can preserve required proof outputs

If preflight fails, do not fake execution.

### 2. Start
When execution begins, the runtime should record:
- start time
- route reference
- adapter/provider reference
- initial policy snapshot

### 3. Mid-flight deviation
If the selected path degrades or becomes unavailable, the runtime should check:
- is fallback allowed?
- which fallback types are allowed?
- is a new route selection required?
- does continuing risk violating hard constraints?

### 4. Completion
On completion, the runtime should record:
- delivered output reference
- usage/metering reference
- whether fallback was used
- whether any partial completion occurred

### 5. Abort / refusal
If the runtime cannot complete inside policy, it should emit a normalized abort/failure record rather than improvising.

---

## Fallback handling

Fallback is not a runtime improvisation layer. It must remain policy-bound.

### Allowed runtime actions
Depending on the execution policy envelope, a runtime may:
- retry on the same provider
- switch to an allowed substitute provider
- downgrade quality within allowed bounds
- defer within the allowed window
- return partial completion if allowed

### Disallowed runtime actions
A runtime should not:
- silently downgrade privacy
- silently exceed the allowed time window
- silently substitute an unapproved provider class
- silently convert a full-only right into partial completion

---

## Agent-native interpretation

For autonomous agents, the execution policy should shape behavior directly.

### Example agent behaviors
- refuse to call tools that would violate provider/privacy policy
- stop a multi-step workflow if remaining time window is insufficient
- request a fresh route quote if the original route lock expires
- avoid branching into a fallback path unless the policy explicitly permits it
- preserve route and execution metadata as first-class artifacts

### Key idea
Agents should not treat execution policy as a comment. It should influence planning and action selection.

---

## Human approval and operator hooks

Some runtime environments may include a human-in-the-loop or operator gate.

Examples:
- approval required before using an expensive fallback route
- approval required before private-local execution exports data externally
- approval required before a route re-lock on a different provider

If so, the execution policy should make that explicit.

This keeps intervention policy structured instead of ad hoc.

---

## Required runtime outputs

Every execution attempt should emit a normalized result object.

```json
{
  "executionResultId": "execres_01",
  "requestId": "req_01",
  "routeRef": "route_01",
  "status": "completed|partial|failed|expired|cancelled|deferred",
  "fallbackUsed": false,
  "proofRefs": [
    "proof_route_lock_01",
    "proof_exec_log_01",
    "proof_meter_01"
  ],
  "notes": {
    "deviationReason": null,
    "runtimePolicyAbort": false
  }
}
```

This object is not yet the full settlement result, but it gives settlement a clean normalized execution fact pattern.

---

## Relationship to execution adapters

Execution adapters handle provider-specific translation.

Execution policy tells the runtime what adapter behavior is allowed.

That distinction matters:
- adapter = how to call the backend
- execution policy = what the runtime is allowed to do while calling it

---

## Relationship to worked examples

The worked examples show what end-to-end flows look like.

This document explains the missing middle layer that makes those examples executable by real agents and workflow systems.

---

## Open questions

- should route locks be renewable by the runtime or only by the router?
- how should multi-step agent workflows report intermediate proof artifacts?
- when should a runtime re-enter routing versus self-applying an allowed fallback?
- should runtime approval hooks be part of the protocol surface or deployment-local only?
- how should local/private execution evidence be standardized across runtimes?

---

## v0 takeaway

Routing chooses the path.
Execution policy makes that path operationally enforceable.

If Synthference wants to be agent-native, it needs a clear contract for how autonomous runtimes turn route decisions into compliant execution behavior.
