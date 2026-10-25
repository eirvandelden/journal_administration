# Intent: Split form asks the amount before the category

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.
Delivery: autonomous. Codex review: no.

## Problem

The "add split" form on a transaction asks for the category first and the amount second. The amount decides what the split is about, so it should come first.

## Proposed outcome

The form asks for the amount first, then the category, then the note.

## Affected users and systems

- Household members who split a transaction (`app/views/transaction_splits/_table.html.erb`, the add form).

## Constraints

- No new dependencies, migrations or deploy changes.

## In scope

- Field order in the add-split form: amount, category, note.

## Out of scope

- The column order of the splits table.
- Autofocus on the amount field.
- The appropriation picker and any other form.

## Acceptance criteria

- On a transaction page, the add-split form shows the amount field before the category field, and the note field last.

## Decisions

- Table columns stay as they are — "defaults".
- No autofocus on the amount field — "defaults".

## Open questions

None.
