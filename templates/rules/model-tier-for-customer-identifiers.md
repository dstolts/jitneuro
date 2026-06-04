---
type: rule
purpose: BINDING for every agent or orchestrator selecting model tiers for pipeline prompts -- any prompt whose output the customer acts on via copy-paste of an exact identifier (part numbers, SKUs, NSNs, regulatory codes) MUST use Sonnet or higher; using Haiku means fabricated-but-plausible identifiers reach customers who order wrong parts or trigger safety incidents.
trigger: any agent performing a model-selection review, performance audit, or building a pipeline section that outputs part numbers, SKUs, NSNs, OEM codes, regulatory citations, or any identifier a customer will copy and use directly
tags: [model-selection, haiku, sonnet, fabrication, customer-safety, parts-sourcing]
read_when: When selecting model tiers for any pipeline prompt whose output includes part numbers, SKUs, NSNs, regulatory codes, or any identifier the customer will copy and use directly -- using Haiku means fabricated-but-plausible identifiers reach customers who order wrong parts or trigger safety incidents.
scope: public
last_evaluated: 2026-06-03
origin: promoted from personal memory (feedback_haiku_fabricates_parts.md) -- Knowledge session 2026-06-01
---

# Model Tier for Customer Identifiers

## Rule

Any prompt whose output the customer ACTS ON via copy-paste of an exact identifier
MUST use Sonnet or higher. Haiku is prohibited for these prompts regardless of cost
or latency pressure.

Identifier types in scope (non-exhaustive):
- Part numbers, SKUs, MPNs (manufacturer part numbers)
- NSNs (national stock numbers), OEM codes
- Regulatory citation codes, compliance standard references
- Model codes, serial number formats used for ordering or lookup

Evaluation per prompt in a pipeline: a pipeline may have Haiku-suitable sections
(e.g., documentation generation, summarization, classification without IDs). Evaluate
each prompt section independently. The identifier-producing section uses Sonnet+;
other sections may use cheaper models.

In performance audits or model-selection reviews, DO NOT propose Haiku as a tier
downgrade for identifier-producing prompts. Document this constraint explicitly so
the next audit does not re-propose it.

## Why

Haiku generates plausible-looking but incorrect part numbers. A customer who receives
a fabricated part number orders the wrong part, wastes money, or creates a safety
incident. The cost of one wrong identifier delivered to a customer dwarfs the lifetime
savings from the Haiku cost delta.

Origin incident (2026-05-16 performance audit): audit proposed downgrading
the `parts-sourcing` section to Haiku (~$0.02/run saved, 1-3s faster). Owner rejected:
"must use expensive model, haiku fabricates part numbers, document so you do not try
to do this again. leave parts separate."

Other sections in the same pipeline (e.g., `documentation`) are already Haiku
and remain Haiku -- the constraint is targeted, not a blanket ban.

## What violates this rule

- Proposing or implementing Haiku on a `parts-sourcing`, `parts-lookup`, or any
  identifier-generation prompt in a perf audit.
- Downgrading an identifier-producing prompt to Haiku because "it looks like
  summarization and summarization is Haiku-suitable."
- Not documenting the Sonnet+ requirement in the pipeline spec so future audits
  rediscover the same violation.

## Origin

Owner correction 2026-05-16 during a performance audit. Generalizes:
Haiku fabrication risk on exact-identifier prompts is a structural model limitation,
not a project-specific quirk.
