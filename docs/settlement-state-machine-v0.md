# Synthference Settlement State Machine v0

## Goal

Define the canonical state machine that turns a Synthference execution receipt into finalized right-state, balance, refund, and dispute outcomes.

If the right schema defines the claim, the request envelope invokes it, and the execution receipt records the outcome, the settlement state machine defines **how the system decides what that outcome means economically and structurally**.

---

## Design principles

1. **Deterministic** - equivalent receipts should settle the same way
2. **Bounded** - settlement cannot create hidden open-ended liabilities
3. **Receipt-driven** - execution receipts are the canonical settlement input
4. **Policy-respecting** - fallback and partial outcomes only count if allowed by the right/request policy envelope
5. **Dispute-aware** - settlement can be final or challengeable depending on proof sufficiency and dispute window
6. **Composable** - supports simple single-route fills and complex split/deferred flows

---

## Core settlement inputs

A settlement engine should consume at minimum:

- the **right** object
- the **request envelope**
- the **execution receipt**
- the **effective execution policy** derived during routing
- any required **proof artifacts**

Settlement should not rely on provider-specific hidden context when the normalized receipt and referenced proofs are sufficient.

---

## Settlement objectives

The state machine must determine:

1. whether the request outcome is `full`, `fallback`, `partial`, `failed`, `expired`, or `cancelled`
2. how much of each referenced right is consumed
3. whether refunds, credits, or reissuance are owed
4. whether supplier-side payout/credit events should fire
5. whether the result is immediately final or enters a disputeable period

---

## State layers

There are really two linked state machines:

1. **request settlement state**
2. **right balance/state transition**

They should be modeled together, but not confused.

---

## Request settlement states

### Primary states
- `unsettled`
- `pending_proof`
- `classified_full`
- `classified_fallback`
- `classified_partial`
- `classified_failed`
- `classified_expired`
- `classified_cancelled`
- `pending_dispute_window`
- `in_dispute`
- `finalized`
- `reversed`

### Notes
- `classified_*` means the engine has interpreted the receipt
- `pending_dispute_window` means economics are tentatively assigned but not fully final
- `reversed` exists for successful disputes or invalidated receipts

---

## Right lifecycle states

A right may already have local registry states like:
- `issued`
- `active`
- `partially_consumed`
- `fully_consumed`
- `expired`
- `settled`
- `disputed`

Settlement is what causes movement across those states.

---

## High-level flow

```text
unsettled
  -> pending_proof
  -> classified_full | classified_fallback | classified_partial | classified_failed | classified_expired | classified_cancelled
  -> pending_dispute_window | finalized
  -> in_dispute (optional)
  -> finalized | reversed
```

---

## Classification rules

### 1. Full
Classify as `classified_full` when:
- receipt status indicates successful completion
- no fallback outside allowed policy occurred
- delivered output satisfies requested shape and minimum constraints
- required proofs are present
- usage is within allowed bounds

### 2. Fallback
Classify as `classified_fallback` when:
- execution completed
- fallback occurred
- fallback was explicitly permitted by the effective fallback policy
- required proofs are present
- delivered result remains inside allowed degraded bounds

### 3. Partial
Classify as `classified_partial` when:
- some valid work was delivered
- request was only partially satisfied
- partial fill is allowed by right/request policy
- proofs support the delivered subset

### 4. Failed
Classify as `classified_failed` when:
- execution produced no valid satisfiable outcome
- or policy bounds were violated
- or required proofs are missing and cannot be recovered
- or delivery failed in a way the protocol treats as non-completion

### 5. Expired
Classify as `classified_expired` when:
- the usable right window elapsed before valid completion
- or deferred execution missed its allowed deadline/window

### 6. Cancelled
Classify as `classified_cancelled` when:
- request was cancelled by an authorized actor before meaningful consumption
- or settlement policy explicitly treats pre-execution abort as cancellation rather than failure

---

## Proof gate

Before final classification, the engine should decide whether proof sufficiency is met.

### If proofs are sufficient
Proceed to classification.

### If proofs are missing but recoverable
Move to `pending_proof`.

### If proofs are missing and unrecoverable
Classify as `failed` or mark dispute-eligible immediately, depending on policy.

---

## Balance impact rules

### Full
- deduct actual consumed units
- release any unused reserved units
- emit supplier credit/payout event for fulfilled portion
- if right remaining balance > 0, stay `active` or `partially_consumed`
- if depleted, move to `fully_consumed` then `settled`

### Fallback
- deduct actual consumed units according to fallback terms
- apply any fallback compensation rules if defined
- emit supplier credit/payout event
- if fallback implies holder compensation, issue refund/credit/reissue delta

### Partial
- deduct only validated delivered units
- release unconsumed reserved capacity
- optionally mint or assign replacement capacity if settlement policy says `credit-reissue`
- keep right `active` if balance remains

### Failed
- do not deduct successful delivery units unless a policy explicitly allows charging for failed attempts
- release reserved capacity unless policy defines a non-refundable reservation fee
- no normal supplier payout unless policy allows attempt compensation

### Expired
- unused balance transitions according to right terms
- may burn, roll, or reissue depending on policy
- no successful fulfillment payout unless a valid partial/fallback completed before expiry

### Cancelled
- generally release reservation
- consume only any non-recoverable committed amount if policy allows it

---

## Refund / compensation modes

Settlement policy can define one of several compensation lanes:

- `none`
- `pro-rata`
- `credit-reissue`
- `custom`

### `none`
No holder compensation beyond unused reservation release.

### `pro-rata`
Holder receives proportional refund or balance restoration for undelivered portion.

### `credit-reissue`
Holder receives a fresh right or right-fragment instead of simple balance return.

### `custom`
External or programmable policy decides the outcome.

---

## Dispute logic

### Enter dispute window
After classification, if the right's `disputeWindowSeconds` > 0 and the proof class is disputeable:
- transition to `pending_dispute_window`
- record tentative balance changes
- record tentative payout/refund events

### Enter dispute
Move to `in_dispute` when:
- holder contests quality/compliance
- supplier contests usage accounting
- proofs conflict
- coordinator detects inconsistency

### Finalize dispute outcome
- if original classification stands -> `finalized`
- if classification is invalidated -> `reversed`
- if reclassified -> return to appropriate `classified_*` state, then finalize again

---

## Finalization rules

Move to `finalized` when:
- classification is complete
- balance adjustments are applied
- payout/refund events are emitted
- dispute window elapsed without challenge, or challenge resolved

At `finalized`, the system should be able to answer:
- what happened
- what was charged
- what remains
- what was paid out
- whether the right is still usable

---

## State transition table

| From | Condition | To |
|---|---|---|
| `unsettled` | receipt/proofs received incompletely | `pending_proof` |
| `unsettled` | receipt + proofs sufficient | `classified_*` |
| `pending_proof` | proofs completed | `classified_*` |
| `pending_proof` | proofs unrecoverable | `classified_failed` |
| `classified_*` | no dispute window required | `finalized` |
| `classified_*` | dispute window required | `pending_dispute_window` |
| `pending_dispute_window` | challenge opened | `in_dispute` |
| `pending_dispute_window` | window elapsed cleanly | `finalized` |
| `in_dispute` | challenge rejected | `finalized` |
| `in_dispute` | challenge upheld | `reversed` or reclassified state |
| `reversed` | corrected settlement applied | `finalized` |

---

## Example settlement paths

### Path A: clean full completion
1. request executes successfully
2. receipt proves full in-bounds completion
3. classify `full`
4. deduct actual units
5. emit payout
6. wait dispute window
7. finalize

### Path B: allowed fallback
1. primary route unavailable
2. allowed fallback route completes
3. receipt marks fallback + bounded degradation
4. classify `fallback`
5. deduct units, apply any compensation rule
6. finalize after dispute window

### Path C: partial then reissue
1. request partially completes
2. receipt shows validated partial delivery
3. classify `partial`
4. deduct delivered units only
5. create replacement right fragment for undelivered portion
6. finalize

### Path D: proof failure
1. execution claims success
2. required proof artifacts missing
3. move `pending_proof`
4. proofs never arrive
5. classify `failed`
6. release reserved capacity
7. finalize

### Path E: expiry
1. request deferred
2. usable window closes before valid completion
3. classify `expired`
4. apply expiry policy (burn/roll/reissue)
5. finalize

---

## Relationship to the right registry

Settlement should emit explicit registry events such as:

- `right.partially_consumed`
- `right.fully_consumed`
- `right.expired`
- `right.dispute_opened`
- `right.dispute_closed`
- `right.reissued`
- `right.settled`

This keeps the registry as the observable source of current right state while the settlement engine remains the state transition authority.

---

## Minimal v0 implementation advice

For a first real implementation, keep settlement simple:

1. single canonical receipt per request
2. deterministic full/fallback/partial/failed/expired classification
3. pro-rata or credit-reissue only
4. one dispute window model
5. append-only settlement events

Do not overcomplicate v0 with exotic multi-party appeals unless the supply model truly requires it.

---

## Open questions

- Should dispute windows differ by supplier class or right class?
- Should fallback compensation be standardized or issuer-defined?
- Should deferred requests reserve balance continuously or only on execution?
- How should split-route partial failures roll up when one leg succeeds and another fails?
- Should settlement support reversible provisional payouts before dispute finality?
