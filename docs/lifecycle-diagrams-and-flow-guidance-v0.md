# Synthference Lifecycle Diagrams and Flow Guidance v0

## Goal

Provide compact lifecycle diagrams and flow-oriented guidance so the Synthference spec set is easier to implement, inspect, and explain.

This document does not replace the detailed specs.
It connects them into readable end-to-end operational paths.

---

## Why this matters

At this point the protocol has separate documents for:
- right schema
- request invocation
- execution receipts
- settlement state
- supplier taxonomy
- assurance
- routing/execution policy
- issuance paths
- registry events
- packaging semantics

That is useful depth, but people also need a top-down map.

This document is that map.

---

## Diagram 1: High-level protocol lifecycle

```text
Capacity basis
   -> issuance policy
   -> right issued
   -> right activated
   -> request submitted
   -> route evaluated
   -> route locked
   -> execution started
   -> execution completed
   -> receipt recorded
   -> settlement classified
   -> dispute window (if any)
   -> finalized outcome
```

### Interpretation
This is the core Synthference story in one line:
capacity justifies issuance, issuance creates a right, a right funds a request, routing chooses a path, execution produces facts, and settlement decides the final result.

---

## Diagram 2: Right lifecycle

```text
issued
  -> activated
  -> active
  -> partially_consumed
  -> fully_consumed
  -> finalized

issued
  -> activated
  -> active
  -> expired
  -> finalized

issued
  -> amended
  -> active

issued
  -> replaced
  -> finalized
```

### Notes
- not every right must pass through every state
- amendment does not mean replacement
- finalization is distinct from simple depletion or expiry
- some rights may remain active after many requests if balance remains

---

## Diagram 3: Request and route lifecycle

```text
request.submitted
  -> request.accepted
  -> route.quoted
  -> route.locked
  -> execution.started
  -> execution.completed
  -> receipt.recorded
  -> settlement.classified
  -> settlement.finalized
```

### Alternate route path

```text
route.quoted
  -> route.locked
  -> route.expired
  -> route.replaced
  -> route.locked
```

### Notes
Routing is dynamic while the right remains durable.
That separation is one of the key protocol ideas.

---

## Diagram 4: Settlement classification map

```text
receipt + policy + proof
   -> full
   -> fallback
   -> partial
   -> failed
   -> expired
   -> cancelled
```

### Settlement follow-through

```text
classified outcome
   -> balance adjustment
   -> holder compensation logic (if any)
   -> supplier credit/payout logic (if any)
   -> dispute window
   -> finalization or reversal
```

### Notes
Settlement is not just labeling.
It decides balance movement, payout logic, refund/reissue treatment, and finality.

---

## Diagram 5: Packaging and delegation flow

```text
issued rights
   -> bundle | slice | tranche | delegation
   -> request references package/delegation
   -> router resolves to concrete underlying right(s)
   -> execution uses concrete route
   -> settlement resolves against concrete right lineage
```

### Notes
Packaging can simplify control surfaces, but execution and settlement still need to resolve to actual underlying rights.

---

## Diagram 6: Registry event memory

```text
right.issued
right.activated
request.submitted
route.quoted
route.locked
execution.started
execution.completed
receipt.recorded
settlement.classified
right.balance_changed
settlement.pending_dispute_window
settlement.finalized
right.finalized
```

### Notes
The event stream is the durable protocol memory.
Current state is a view derived from that history.

---

## Flow 1: Clean reserved-capacity fulfillment

### Steps
1. issuer creates a reserved right against a valid assurance basis
2. holder submits a compatible request
3. router selects an interactive route
4. route lock succeeds
5. execution completes successfully
6. receipt is recorded with required proofs
7. settlement classifies `full`
8. right balance is decremented
9. request and settlement finalize after the dispute window or immediately if policy allows

### Mental model
This is the baseline "everything worked" path.
Every other path should be understandable as a controlled deviation from this one.

---

## Flow 2: Allowed fallback path

### Steps
1. request is submitted under a right with allowed fallback
2. preferred route becomes unavailable or degraded
3. router or runtime checks fallback bounds
4. an allowed substitute route is selected
5. execution completes on the substitute path
6. receipt records the fallback facts
7. settlement classifies `fallback`
8. compensation or credit adjustments apply if policy requires them

### Mental model
A fallback is not a fake full success.
It is a valid, named outcome inside the bounded contract.

---

## Flow 3: Partial fulfillment path

### Steps
1. a multi-unit request is submitted
2. only part of the request can be delivered within policy bounds
3. execution records the valid delivered subset
4. receipt and metering reflect partial delivery
5. settlement classifies `partial`
6. only validated delivered units are consumed
7. remaining balance or replacement treatment follows policy

### Mental model
Partial is a first-class settlement state, not an awkward corner case.

---

## Flow 4: Expiry path

### Steps
1. right or route window is nearing the end
2. execution begins too late or stalls too long
3. no valid completion lands before the allowed deadline
4. proofs show elapsed window and lack of recognized valid completion
5. settlement classifies `expired`
6. unused balance is handled by expiry policy

### Mental model
Time is structural here, not incidental.
The protocol is designed to say "too late" in a clean way.

---

## Flow 5: Delegated agent execution path

### Steps
1. parent holder delegates a bounded usage slice to a child agent or app session
2. delegated actor submits a request inside delegated bounds
3. router resolves to compatible underlying right lineage
4. execution policy is enforced against delegated scope plus underlying right constraints
5. execution completes
6. registry and settlement record both the underlying right reference and delegation lineage

### Mental model
Delegation allows agent-native execution control without needing full ownership transfer every time.

---

## Implementation guidance

### Start with the clean path
If building a first implementation, support this order:
1. direct right issuance
2. clean request + route + receipt + settlement flow
3. fallback handling
4. partial handling
5. registry event history
6. packaging/delegation

### Do not flatten distinctions too early
Keep these separate in code and data:
- right vs route
- route vs execution
- receipt vs settlement
- amendment vs replacement
- package vs underlying right

### Prefer explicit event emission
If something meaningful happened, record it.
Silent mutation makes later reasoning worse.

### Treat proof capture as part of execution
Do not bolt it on at the end.
The runtime should know what evidence must survive before the request is even fired.

---

## Suggested implementation checkpoints

### Checkpoint 1: issuance correctness
Can the system explain why a right exists?

### Checkpoint 2: routing clarity
Can the system explain why a route was chosen?

### Checkpoint 3: execution discipline
Can the runtime refuse invalid fallback or invalid timing?

### Checkpoint 4: settlement determinism
Would two evaluators settle the same request the same way from the same receipt set?

### Checkpoint 5: registry memory
Can you reconstruct the lifecycle of one right or request from normalized events?

### Checkpoint 6: packaging honesty
Can a package still resolve back to concrete underlying rights and policies?

---

## Suggested reading order for builders

1. `README.md`
2. `schema-v0.md`
3. `request-envelope-v0.md`
4. `execution-receipt-v0.md`
5. `settlement-state-machine-v0.md`
6. `system-modules-v0.md`
7. `agent-execution-policy-v0.md`
8. `registry-event-model-v0.md`
9. `worked-examples-v0.md`
10. packaging / issuance / assurance docs as needed

This gives a builder the shortest path from top-level idea to implementation-critical detail.

---

## v0 takeaway

Synthference is easiest to understand when seen as a lifecycle:
issue bounded rights, route requests against them, execute under explicit policy, record proofs, settle deterministically, and preserve the full history in registry events.

The diagrams and flows here are meant to keep the whole shape visible while the deeper docs handle the exact machinery.
