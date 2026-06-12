# Synthference Issuance Paths v0

## Goal

Compare the main issuance paths Synthference can support across centralized and decentralized supply, and define how those paths differ structurally.

This document is not trying to declare a single winner.
Its job is to make the tradeoffs explicit enough that implementations can choose an issuance path on purpose.

---

## Why this matters

A Synthference right can look identical at the schema layer while being created from very different operational realities.

Examples:
- a centralized coordinator minting rights against hosted provider reservations
- a decentralized network minting rights against posted node inventory
- an enterprise issuing internal rights against a private cluster
- a hybrid system issuing rights against reserved baseline capacity plus overflow inventory

If the protocol ignores those differences, it will end up pretending that all issuance is equally reliable, equally observable, and equally governable.

It is not.

---

## Design principles

1. **Same primitive, different issuance lanes** - the right shape can stay consistent while issuance mechanics differ
2. **Operational honesty** - issuance path should reflect how capacity is actually sourced and controlled
3. **Assurance-first comparison** - compare paths by their capacity assurance properties, not just ideology
4. **Settlement compatibility** - issuance path should not break downstream routing and settlement expectations
5. **Composable migration** - systems should be able to start centralized and evolve toward more federated models

---

## Core issuance paths

### 1. Centralized coordinator issuance
A single operator or tightly controlled service issues rights against capacity it directly reserves, purchases, or manages.

### 2. Supplier self-issuance
Suppliers issue rights directly against their own declared and policy-bounded capacity.

### 3. Registry-mediated federated issuance
Suppliers publish inventory into a shared registry, and a coordinator or protocol-controlled service issues rights against accepted inventory slices.

### 4. Enterprise private issuance
An enterprise or local operator issues rights internally against dedicated private-cluster or local-runtime capacity.

### 5. Hybrid issuance
A system combines two or more issuance lanes, such as reserved centralized baseline plus federated overflow capacity.

---

## Path 1: Centralized coordinator issuance

### Structure
A central issuer controls:
- right creation
- inventory policy
- assurance policy
- route admission policy
- often the settlement ledger as well

### Typical supply basis
- reserved hosted-provider capacity
- prepaid provider allotments
- owned cluster slices
- coordinator-controlled execution gateways

### Strengths
- easiest path to launch
- clearer policy control
- simpler audit and support surface
- easier to normalize proofs and routing behavior
- easier to maintain premium or tight-SLA rights

### Weaknesses
- stronger trust concentration
- less supply diversity
- single coordinator policy can become a bottleneck
- portability may be weaker if everything depends on one operator's private controls

### Best fit
- early-stage product rollout
- premium workloads
- narrow workload classes
- hosted inference products with strong UX goals

---

## Path 2: Supplier self-issuance

### Structure
Each supplier creates rights directly against its own declared capacity and policy profile.

### Typical supply basis
- operator-owned nodes
- provider-owned API capacity
- dedicated cluster allocations
- local node capacity with public issuance exposure

### Strengths
- issuance authority stays close to the supply
- suppliers can express differentiated classes of rights
- less coordinator dependency for right creation
- can encourage a more open supply ecosystem

### Weaknesses
- inconsistent policy quality across issuers
- higher verification burden for holders and routers
- harder to compare assurance quality across suppliers
- more fragmentation risk in right semantics and trust profiles

### Best fit
- open ecosystems with diverse suppliers
- operator-first markets
- environments where suppliers already have strong identity and reputation layers

---

## Path 3: Registry-mediated federated issuance

### Structure
Suppliers publish inventory and capability slices into a shared registry.
A registry-governed issuer or coordinator then issues rights against accepted inventory slices.

### Typical supply basis
- posted node inventory
- delegated supplier windows
- accepted supplier capability listings
- measured and policy-filtered federated capacity

### Strengths
- supply diversity without fully unstructured issuance
- more uniform right semantics than pure self-issuance
- stronger ability to apply protocol-wide assurance and haircut policy
- can scale beyond a single provider base while keeping issuance comparable

### Weaknesses
- more moving parts than centralized issuance
- registry quality becomes critical
- delayed or stale inventory can corrupt issuance assumptions if refresh policy is weak
- harder than centralized issuance to guarantee premium claims tightly

### Best fit
- multi-supplier networks
- coordinator-based mesh systems
- ecosystems that want open supply with policy-curated issuance

---

## Path 4: Enterprise private issuance

### Structure
An internal issuer creates rights for internal apps, agents, or teams against private-cluster or local-runtime capacity.

### Typical supply basis
- dedicated inference clusters
- local isolated runtimes
- internal AI gateways
- policy-controlled departmental capacity pools

### Strengths
- strongest privacy and governance control
- local policy integration is easier
- assurance logic can align tightly with known internal infrastructure
- good fit for sensitive or regulated workflows

### Weaknesses
- less open portability by default
- smaller supply diversity
- may rely on internal assumptions that do not generalize well externally

### Best fit
- enterprise internal platforms
- regulated workloads
- privacy-sensitive agent systems

---

## Path 5: Hybrid issuance

### Structure
The issuer combines multiple supply lanes into a staged or layered issuance model.

### Example patterns
- reserved centralized baseline + federated overflow
- private-cluster first + hosted fallback
- supplier self-issuance wrapped by a coordinator-normalized vault

### Strengths
- most flexible path
- can improve resilience and routing diversity
- supports graceful migration from closed to open supply
- lets products separate premium, standard, and overflow lanes cleanly

### Weaknesses
- hardest to explain and govern
- requires sharp policy boundaries between lanes
- proof and settlement complexity increase quickly
- poor abstraction can hide risk instead of reducing it

### Best fit
- mature systems
- multi-tier product lines
- migration paths from centralized v1 to broader supply participation

---

## Comparison axes

### 1. Assurance strength
How directly and reliably the issuer can justify the right's existence.

### 2. Supply diversity
How many heterogeneous suppliers can realistically participate.

### 3. Policy uniformity
How consistent right semantics remain across issuers and supply sources.

### 4. Operational complexity
How hard it is to keep issuance, routing, and refresh behavior honest.

### 5. Trust concentration
How much the system depends on one operator or governance center.

### 6. Portability
How easily the model can travel across products, networks, or organizations.

---

## Practical comparison

| Path | Assurance strength | Supply diversity | Policy uniformity | Operational complexity | Trust concentration |
| --- | --- | --- | --- | --- | --- |
| Centralized coordinator | High | Low-Medium | High | Low-Medium | High |
| Supplier self-issuance | Variable | High | Low | Medium | Low-Medium |
| Registry-mediated federated | Medium-High | High | Medium-High | High | Medium |
| Enterprise private | High | Low | High | Medium | Medium-High |
| Hybrid | Variable | High | Medium | Highest | Variable |

---

## Relationship to capacity assurance

Issuance path and assurance mode are related but separate.

Examples:
- a centralized coordinator may use `reserved-capacity`
- a federated registry may use `inventory-posted` or `historical-availability`
- an enterprise private lane may use `local-allocation`
- a hybrid system may combine multiple assurance modes

The issuance path tells us **who issues and under what governance structure**.
The assurance mode tells us **what capacity basis justifies issuance**.

---

## Relationship to routing

Routing behavior should often reflect the issuance path.

Examples:
- centralized premium rights may allow tighter route guarantees
- federated rights may need more explicit fallback posture
- hybrid rights may require lane-aware routing and proof tracking
- enterprise rights may treat privacy as a hard dominant constraint

This is why issuance is not just a minting concern. It shapes the runtime character of the right.

---

## Relationship to settlement

Different issuance paths may demand different settlement conservatism.

Examples:
- supplier self-issued rights may require stronger proof or longer dispute windows
- centralized coordinator rights may settle faster if proofs are tightly normalized
- hybrid rights may need lane-specific settlement policies depending on which supply lane actually fulfilled the request

---

## Recommended v0 posture

For v0, the cleanest rollout path is usually:

1. start with centralized coordinator issuance or enterprise private issuance
2. normalize right semantics and proof expectations
3. introduce registry-mediated federated issuance once capability taxonomy and assurance policy are stable
4. add hybrid lanes only after settlement and routing behavior are already trustworthy

This does not mean centralized is the end state.
It means operational discipline matters more than ideological purity in the early protocol phase.

---

## Open questions

- should issuance path be an explicit field in the right or issuer metadata?
- when should federated inventory be accepted directly versus wrapped by a coordinator-normalized issuer?
- how should right holders compare assurance quality across self-issued rights?
- when should one workload class support multiple issuance lanes simultaneously?
- should settlement policy defaults vary automatically by issuance path?

---

## v0 takeaway

Synthference can support multiple issuance paths, but it should not pretend they are interchangeable.

The right primitive may be shared, yet the path that creates the right changes the trust model, assurance posture, routing behavior, and operational complexity around it.
