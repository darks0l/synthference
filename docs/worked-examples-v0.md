# Synthference Worked Examples v0

## Goal

Make the protocol easier to reason about by walking through concrete end-to-end examples.

These examples are illustrative. They are meant to show how the spec pieces fit together, not to freeze one implementation.

---

## Example 1: Full fulfillment on a reserved text right

### Setup
A developer agent holds a reserved text-generation right.

### Right summary
- workload class: `text.generation`
- unit: `tokens`
- amount: `200000`
- latency band: `interactive`
- privacy mode: `shared-remote`
- fallback allowed: yes
- window: 7 days

### Request
The agent submits a request for a structured JSON generation task.

### Flow
1. holder submits request envelope
2. router checks candidate rights
3. router selects a matching interactive hosted provider
4. route is locked
5. execution adapter submits the job
6. provider returns valid output
7. receipt references execution log, metering record, and output reference
8. settlement classifies outcome as `full`
9. consumed tokens are deducted from the right

### Result
- request state: `finalized`
- outcome: `full`
- right state: `partially_consumed`
- unused balance remains active

### Why it matters
This is the clean baseline path the rest of the protocol is measured against.

---

## Example 2: Allowed fallback from premium to high

### Setup
A holder has a premium image-generation right with bounded fallback.

### Right summary
- workload class: `image.generation`
- quality band: `premium`
- latency band: `interactive`
- fallback allows quality downgrade to `high`
- fallback does not allow privacy downgrade

### Request
The holder requests one product image render.

### Flow
1. router tries premium path first
2. premium path becomes temporarily unavailable
3. router checks fallback policy intersection
4. a `high` quality hosted route is permitted
5. execution completes on the fallback route
6. receipt includes fallback reason and route-selection record
7. settlement classifies outcome as `fallback`

### Result
- request state: `finalized`
- outcome: `fallback`
- right consumed according to fallback settlement terms
- any fallback compensation logic is applied if the policy requires it

### Why it matters
The system does not pretend the fallback was identical. It recognizes it explicitly while still allowing bounded completion.

---

## Example 3: Partial batch fulfillment within window

### Setup
A workflow manager holds a background batch GPU right for five jobs.

### Right summary
- workload class: `gpu.batch`
- unit: `jobs`
- amount: `5`
- latency band: `batch`
- partial fill allowed: yes
- deferral within window allowed: yes

### Request
The workflow submits five batch rendering jobs.

### Flow
1. router allocates available capacity for only three jobs immediately
2. two jobs cannot complete before the current window closes
3. execution records show three successful completions
4. metering proves three delivered jobs
5. settlement recognizes a `partial` outcome for the submitted request
6. remaining two jobs are either reissued, deferred, or released based on policy

### Result
- request state: `finalized`
- outcome: `partial`
- right balance reduced by three jobs only
- undelivered portion handled by settlement policy

### Why it matters
Partial fulfillment is treated as a first-class protocol outcome, not as an awkward failure case.

---

## Example 4: Expiry before valid completion

### Setup
An app holds a burst right for a narrow launch window.

### Right summary
- workload class: `agent_runtime`
- priority: `premium`
- window ends at 18:00 UTC
- no deferred completion after window end

### Request
The app submits a request at 17:58 UTC.

### Flow
1. route is selected
2. execution begins
3. execution stalls and no valid completion is recorded before 18:00 UTC
4. proof set shows start time, no recognized completion, and expired window
5. settlement classifies outcome as `expired`

### Result
- request state: `finalized`
- outcome: `expired`
- balance treatment follows right policy
- no false success is recorded

### Why it matters
Time scope is part of the primitive. Missing the window is a protocol outcome, not just an operational footnote.

---

## Example 5: Route quote separated from the right

### Setup
A holder owns a valid right but has not yet selected an execution path.

### Principle
The right is the standing claim.
The route quote is the execution-time selection object.

### Flow
1. holder references a right in a request
2. router evaluates current supply
3. router produces one or more route candidates
4. the chosen route is locked for a short period
5. execution proceeds against that locked route
6. receipt references both the right and the route lock

### Why this separation matters
- rights stay durable across changing supply conditions
- routing remains dynamic
- settlement can evaluate whether the consumed route matched the selected route
- the protocol avoids collapsing ownership and execution selection into one object

---

## v0 takeaway

The best way to understand Synthference is to follow a right through invocation, route selection, execution, receipt creation, and settlement.

Worked examples turn the system from abstract vocabulary into a protocol that can actually be inspected and implemented.
