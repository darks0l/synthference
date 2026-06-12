# Synthference Supplier Capability Taxonomy v0

## Goal

Define a normalized capability taxonomy for heterogeneous inference suppliers so Synthference routers can compare, match, and settle supply without collapsing everything into a single provider-specific label.

This taxonomy is intentionally **provider-agnostic**. It is meant to describe what a supplier can reliably deliver, not how the supplier markets itself.

---

## Why a taxonomy is needed

A router cannot make good decisions if suppliers describe themselves with vague or incompatible language.

Examples of bad supplier descriptions:
- "fast"
- "premium"
- "agent-ready"
- "GPU-backed"
- "private"

Those labels are too ambiguous for routing and settlement.

Synthference needs supplier capability metadata that is:
- structured
- comparable across suppliers
- stable enough for rights issuance
- precise enough for fallback logic
- auditable after execution

---

## Design principles

### 1. Capability over branding
Taxonomy entries should describe deliverable behavior, not product names.

Use:
- `text.generation`
- `image.generation`
- `tool.agent-runtime`

Avoid relying on:
- provider SKU names
- model marketing tiers
- ecosystem-specific slang

### 2. Deliverable-first
The taxonomy should reflect what can actually be fulfilled and settled.

### 3. Multi-axis, not one label
Capability is not a single string. It is the combination of:
- workload class
- quality band
- latency band
- privacy mode
- execution environment
- policy constraints

### 4. Support graceful degradation
The taxonomy must let routers determine acceptable substitutions.

### 5. Keep v0 coarse enough to use
v0 should be expressive without becoming impossible to populate.

---

## Capability object

Each supplier should expose one or more capability objects.

### Minimal shape

```json
{
  "capabilityId": "cap_text_interactive_std",
  "workloadClass": "text.generation",
  "qualityBand": "standard",
  "latencyBand": "interactive",
  "privacyMode": "shared-remote",
  "executionEnvironment": "centralized-api",
  "policyConstraints": ["no-pii-guarantee"],
  "availabilityMode": "on-demand"
}
```

---

## Axis 1: Workload class

Defines the primary job type the supplier can execute.

### Core workload classes
- `text.generation`
- `text.classification`
- `text.embedding`
- `image.generation`
- `image.edit`
- `audio.transcription`
- `audio.synthesis`
- `video.generation`
- `tool.agent-runtime`
- `tool.browser-runtime`
- `tool.code-runtime`
- `gpu.batch`
- `custom`

### Notes
- Suppliers may expose multiple workload classes.
- `custom` should be avoided unless a schema extension defines it clearly.

---

## Axis 2: Quality band

Defines the expected quality envelope of delivered results.

### v0 bands
- `economy`
- `standard`
- `high`
- `premium`
- `deterministic`

### Interpretation
- `economy` = lowest-cost acceptable output class
- `standard` = normal production baseline
- `high` = stronger than baseline, better quality consistency
- `premium` = top-tier scarce or expensive supply
- `deterministic` = optimized for reproducibility or constrained variance

### Important note
Quality bands are relative and ecosystem-normalized. They are not claims of universal superiority.

---

## Axis 3: Latency band

Defines the expected responsiveness class.

### v0 bands
- `realtime`
- `interactive`
- `async`
- `batch`

### Interpretation
- `realtime` = sub-second or near-streaming interaction target
- `interactive` = user-facing request/response flow
- `async` = deferred but near-term completion
- `batch` = non-interactive queued fulfillment

---

## Axis 4: Privacy mode

Defines the exposure profile of the workload.

### v0 modes
- `local-isolated`
- `private-cluster`
- `trusted-network`
- `shared-remote`
- `public-network`

### Interpretation
- `local-isolated` = execution on holder-controlled or dedicated local environment
- `private-cluster` = controlled private infrastructure with bounded operator access
- `trusted-network` = third-party or consortium supply with explicit trust assumptions
- `shared-remote` = normal multi-tenant hosted provider execution
- `public-network` = open network or broadly distributed execution environment

### Why this matters
Privacy mode is often a hard routing constraint, not a soft preference.

---

## Axis 5: Execution environment

Defines the operational source of supply.

### v0 environments
- `centralized-api`
- `dedicated-cluster`
- `private-gateway`
- `decentralized-network`
- `local-runtime`
- `agent-hosted-runtime`

This axis matters because two suppliers may expose similar outputs but have radically different failure, trust, and cost behavior.

---

## Axis 6: Policy constraints

Defines routing-relevant restrictions or guarantees.

### Example constraints
- `region-us-only`
- `region-eu-only`
- `no-training-retention`
- `pii-allowed`
- `pii-disallowed`
- `export-controlled`
- `licensed-model-only`
- `open-weights-only`
- `tool-use-enabled`
- `tool-use-disabled`
- `internet-enabled`
- `internet-disabled`

### Notes
- Constraints should be machine-readable.
- Routers should treat some constraints as hard filters and others as preferences.

---

## Axis 7: Availability mode

Defines how the supplier exposes capacity.

### v0 modes
- `reserved`
- `on-demand`
- `burst`
- `spot`
- `scheduled-window`

### Interpretation
- `reserved` = pre-committed capacity
- `on-demand` = generally callable at will
- `burst` = callable for temporary overload handling
- `spot` = cheaper but interruptible or unstable supply
- `scheduled-window` = only available during explicit windows

---

## Optional capability extensions

Suppliers may attach structured extension fields.

### Examples
- `modelFamilies`
- `maxContextWindow`
- `streamingSupported`
- `maxConcurrency`
- `regionalEndpoints`
- `complianceTags`
- `toolProfiles`
- `pricingCurveRef`
- `proofModes`

These should remain optional in v0 so the base taxonomy stays portable.

---

## Capability profiles

Routers will often compare capability profiles rather than raw suppliers.

### Example 1: Hosted premium text path

```json
{
  "capabilityId": "cap_text_premium_interactive_hosted",
  "workloadClass": "text.generation",
  "qualityBand": "premium",
  "latencyBand": "interactive",
  "privacyMode": "shared-remote",
  "executionEnvironment": "centralized-api",
  "policyConstraints": ["no-training-retention"],
  "availabilityMode": "on-demand"
}
```

### Example 2: Local private agent runtime

```json
{
  "capabilityId": "cap_agent_private_local",
  "workloadClass": "tool.agent-runtime",
  "qualityBand": "standard",
  "latencyBand": "async",
  "privacyMode": "local-isolated",
  "executionEnvironment": "local-runtime",
  "policyConstraints": ["internet-disabled"],
  "availabilityMode": "reserved"
}
```

### Example 3: Cheap overflow image generation

```json
{
  "capabilityId": "cap_image_burst_spot",
  "workloadClass": "image.generation",
  "qualityBand": "economy",
  "latencyBand": "batch",
  "privacyMode": "public-network",
  "executionEnvironment": "decentralized-network",
  "policyConstraints": [],
  "availabilityMode": "spot"
}
```

---

## Routing implications

The taxonomy is meant to support decisions like:
- exact match
- acceptable fallback
- forbidden downgrade
- multi-supplier split
- deferred fulfillment

### Example fallback logic
A right requiring:
- `workloadClass = text.generation`
- `qualityBand >= high`
- `latencyBand <= interactive`
- `privacyMode != public-network`

could fall back from:
- `premium` to `high`

but not from:
- `interactive` to `batch`
- `private-cluster` to `public-network`

unless the right explicitly allows it.

---

## Settlement implications

Settlement should reference the same taxonomy used in routing.

This lets the system answer:
- Was the delivered workload class correct?
- Was latency delivered within the promised band?
- Did fulfillment use an allowed privacy mode?
- Was the downgrade inside permitted fallback boundaries?

Without this shared taxonomy, settlement becomes subjective.

---

## Registry integration

Supplier registry entries should expose:
- supplier identity
- one or more capability objects
- availability and pricing metadata
- historical reliability and proof support

Rights issuers can then package supply against capability slices instead of vague provider labels.

---

## Open questions for next versions

- Should quality bands become per-workload-class instead of global?
- Should privacy mode be split into confidentiality and control-plane trust?
- How should fine-tuned or custom models be represented?
- Should deterministic execution be a quality band or a separate axis?
- How should tool-using agent runtimes express internet/tool sub-capabilities?
- Which fields must be attested versus self-declared?

---

## v0 takeaway

Synthference needs a shared language for supply.

The supplier capability taxonomy is that language: a normalized multi-axis description of what a supplier can deliver, under what constraints, with what quality, latency, privacy, and availability characteristics.

That shared language is what makes portable routing and bounded settlement possible in the first place.
