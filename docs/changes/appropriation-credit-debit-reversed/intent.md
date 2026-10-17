# Intent: Appropriations treat credits as charges and debits as refunds

Author: Etienne van Delden de la Haije. Status: accepted. Type: bugfix. Delivery: autonomous.

## Problem

Linking a credit transaction to an appropriation raises its remaining balance. Etienne expects it to lower the balance.

Today `Appropriation#charged` counts debits as charges and subtracts credits as refunds. Until the books use double-entry bookkeeping, the household records the opposite direction for appropriations.

## Proposed outcome

For appropriations, a credit is a charge and a debit is a refund. A linked credit lowers the remaining balance. A linked debit, such as a returned item, raises it.

## Affected users and systems

- The household, on the appropriation index and show pages, which display charged and balance.
- The transaction pages that show the charge, and the assistant (MCP) tools `list_appropriations` and `charge_to_appropriation`, whose output and descriptions use the same figures.
- Whole payments and split parts alike.

## Constraints

- No data migration: charged and balance are computed, so existing links change meaning at once.
- The monthly budget and dashboard keep counting the category as before. Charging never touches the category.
- Approved permissions: none needed (no gems, no dropping migrations, no deploy files).

## In scope

- Reverse the sign rule for whole payments and split parts: charged equals credits minus debits.
- Update the tests, fixtures and wording (descriptions, locale text, doc comments) that describe the old direction.

## Out of scope

- Which transaction types may be linked.
- The monthly budget and dashboard.
- Double-entry bookkeeping.
- Changing stored transaction amounts.

## Acceptance criteria

- Linking a €50 credit to a €200 appropriation shows charged €50 and balance €150.
- Linking a €20 debit to that appropriation as well shows charged €30 and balance €170.
- Linking only a €20 debit shows charged -€20 and balance €220.
- A split part of a credit counts the same way as a whole credit.
- The assistant's `list_appropriations` reports the same charged and balance figures as the pages.

## Open questions

None.
