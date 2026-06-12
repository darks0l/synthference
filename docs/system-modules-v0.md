# Synthference System Modules v0

## Goal

Define the minimal module set required to issue, route, consume, and settle synthetic inference rights.

This is a **general primitive** design, not a DarkMesh-specific architecture.

---

## System overview

Synthference can be thought of as five core layers:

1. **Issuance** - creates rights
2. **Registry** - stores and indexes rights and supplier inventory
3. **Routing** - matches demand against rights and supply
4. **Execution** - performs the underlying inference work
5. **Settlement** - records what actually happened

Optional higher-level layers:
- rebalancers
- secondary markets
- vaults / packaged strategies
- agent policy engines

---

## 1. Rights Issuer

### Purpose
Creates Synthference rights from posted or modeled capacity.

### Responsibilities
- mint rights from supplier inventory
- define right classes (`reserved`, `burst`, `background`, `custom`)
- attach fallback and settlement policies
- prevent over-issuance relative to backing assumptions

### Possible implementations
- centralized operator
- protocol coordinator
- supplier self-issuance
- vault that wraps external capacity

### Key design constraint
The issuer must only create **bounded claims**. It should never silently create open-ended service liabilities.

---

## 2. Supplier Registry

### Purpose
Tracks available execution sources and their advertised capabilities.

### Responsibilities
- register suppliers/providers/nodes/clusters
- expose capability metadata
- expose policy and region constraints
- expose reliability / performance history
- expose available capacity windows

### Example supplier fields
- supplier id
- compute classes supported
- model/capability taxonomy
- privacy mode
- latency profile
- geographic region
- capacity envelope
- pricing curve
- stake / trust / reputation data

### Why it matters
Rights are portable only if supply is normalized enough for routers to compare heterogeneous providers.

---

## 3. Rights Registry

### Purpose
Stores active rights and makes them discoverable by holders, routers, and settlement systems.

### Responsibilities
- index right metadata
- track ownership/control
- track available balance and usage
- track expiry, state, and settlement transitions
- expose event history

### Key states
- `issued`
- `active`
- `partially_consumed`
- `fully_consumed`
- `expired`
- `settled`
- `disputed`

### Notes
This can be offchain first. Onchain representation is optional and should not be assumed in v0.

---

## 4. Router / Matcher

### Purpose
Determines how a request is fulfilled using the holder's rights and the currently available supply.

### Responsibilities
- validate whether a right can satisfy a request
- choose best execution path
- apply fallback policy if needed
- allocate work across one or more suppliers
- preserve policy guarantees while optimizing for cost, speed, privacy, or quality

### Inputs
- request intent
- held rights
- supplier availability
- hard policy constraints
- routing hints

### Outputs
- selected supplier(s)
- selected fulfillment mode (`full`, `fallback`, `partial`)
- execution plan
- expected settlement path

### Routing modes
- single-fill
- multi-fill
- deferred fill
- fallback fill
- split-route fill

### Why this is core
The router is where Synthference stops being a token story and becomes real infrastructure.

---

## 5. Execution Adapter Layer

### Purpose
Connects Synthference routing decisions to actual compute backends.

### Responsibilities
- translate abstract execution plans into provider-specific calls
- meter usage consistently
- capture proofs / logs / outcomes
- surface failure categories in normalized form
- emit normalized execution receipt inputs

### Adapter targets
- centralized inference APIs
- decentralized inference networks
- private cluster gateways
- local node pools
- agent runtime environments

### Design goal
Keep provider-specific weirdness at the edge. The rest of the system should reason in Synthference-native terms.

---

## 6. Metering and Proof Layer

### Purpose
Measure delivered service and produce settlement-relevant facts.

### Responsibilities
- record usage quantity
- record latency class achieved
- record fallback path used
- record completion/failure signals
- package evidence for settlement or dispute

### Possible proofs
- request/response logs
- signed metering records
- completion receipts
- latency measurements
- execution attestations

### Constraint
Proofs must be strong enough for settlement without assuming every supplier is fully trusted.

---

## 7. Settlement Engine

### Purpose
Turn execution results into finalized right state transitions.

### Responsibilities
- classify outcomes as `full`, `fallback`, `partial`, `failed`, or `expired`
- decrement remaining balance
- apply refunds, credits, or reissuance policies
- open and close disputes
- finalize ledger/accounting state

### Settlement outputs
- balance updates
- holder receipts
- issuer obligations
- supplier credits/payment signals
- dispute records

### Core idea
Settlement is not an afterthought. It is part of the primitive itself.

---

## 8. Rebalancer (optional but powerful)

### Purpose
Act on behalf of a holder, app, vault, or agent to manage expiring or drifting rights.

### Responsibilities
- roll rights forward
- swap right classes
- defer low-priority demand
- split demand across new positions
- minimize slippage or underutilization

### Why it matters
This is where the options analogy becomes operational. Instead of hard liquidations, systems rebalance bounded rights under policy.

---

## 9. Secondary Market Layer (optional)

### Purpose
Allow unused or partially used rights to be transferred, sold, or netted.

### Possible functions
- resale marketplace
- bilateral swaps
- auction clearing
- vault packaging
- netting engine for overlapping rights

### Value
This makes compute access more capital-efficient than stranded provider credits.

---

## 10. Agent Policy Engine (optional but likely important)

### Purpose
Let apps or autonomous agents consume rights according to explicit policy.

### Responsibilities
- choose when to spend premium vs background capacity
- enforce privacy or jurisdiction rules
- select human approval thresholds
- decide fallback tolerance
- choose rebalance timing

### Why it fits
Synthference is a natural fit for agent-native infra because rights are policy objects, not just balances.

---

## Minimal v0 stack

If building the first concrete version, I would start with:

### Required
1. Rights issuer
2. Supplier registry
3. Rights registry
4. Router
5. Execution adapters
6. Metering/proof layer
7. Settlement engine

### Optional later
8. Rebalancer
9. Secondary market
10. Agent policy engine

---

## Suggested v0 control flow

### A. Supplier onboarding
1. supplier registers capabilities
2. supplier posts available capacity envelope
3. issuer validates and creates right inventory

### B. Holder acquisition
1. user/app/agent acquires right
2. right becomes active in registry

### C. Execution
1. holder submits a request envelope against one or more rights
2. router validates rights, constraints, and fallback permissions
3. router selects supply path
4. adapter executes request
5. metering layer records outcome

### D. Settlement
1. settlement engine classifies result
2. balance is decremented or adjusted
3. refund/reissue logic applies if relevant
4. right returns to active, partial, consumed, or settled state

---

## Architectural question to watch

The biggest architectural fork is this:

### Is Synthference primarily...
1. a **ledger + router primitive** for apps and agents?
2. a **market primitive** for trading future compute?
3. a **vault primitive** for packaging access guarantees?

My read: start as **ledger + router primitive**.
That gives the cleanest implementation path and still supports markets and vaults later.

---

## Near-term repo follow-ups

- define settlement state machine
- define supplier capability taxonomy
- define dispute boundary and proof minimums
- map request envelope validation into router stages
- define receipt amendment / finalization rules
