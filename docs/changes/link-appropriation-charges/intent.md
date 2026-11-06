# Intent: Link appropriation charges to their transaction

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

The appropriation show page lists what is charged to an appropriation, but a charge is plain text. When a charge sits under the wrong appropriation, Etienne must find the transaction by hand before he can change or remove the charge.

## Proposed outcome

Each charge row on the appropriation show page links to its original transaction. From there Etienne changes the appropriation or removes the charge.

## Affected users and systems

The household members who use the appropriation show page. The view `app/views/appropriations/show.html.erb`. No model, route or schema change is expected.

## Constraints

Follow the existing table and link style. Strings go through i18n. The charge form on the transaction page already changes or removes a charge; this change reuses it.

## In scope

- A link on the amount of each charge row of the appropriation show page.
- A whole-payment charge links to that transaction.
- A split-part charge links to the transaction it splits.

## Out of scope

- Changing or removing a charge from the appropriation page itself.
- Changes to the transaction page or its charge form.
- Other pages that list charges.

## Acceptance criteria

- The amount of a charge that is a whole payment links to the page of that transaction.
- The amount of a charge that is a split part links to the page of its parent transaction.
- An appropriation with no charges still shows "Nothing is charged to this appropriation yet." and no link.

## Decisions

- The amount cell carries the link — other pages already link the amount to the original, so this page matches them.

## Open questions

None.
