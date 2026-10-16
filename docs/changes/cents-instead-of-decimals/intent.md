# Intent: Store money as integer cents

Author: Etienne van Delden. Status: accepted. Type: refactor. Delivery: autonomous

## Problem

Amounts live in decimal columns, so half cents can enter the books through arithmetic such as splits and receipt lines. A half cent changes a total that a user sees, and no bank statement has one.

## Proposed outcome

Every money amount is stored as a whole number of cents: what is 1,5 today becomes 150. Users still type and read 1,50 in the interface. No amount that a user sees goes up or down because of the change.

## Affected users and systems

- All users: forms and views that show or take an amount.
- Columns: appropriations.amount, budget_categories.amount, chattels.purchase_price, receipt_lines.full_amount, discount_amount and paid_amount, receipts.total_amount, transaction_splits.amount, transactions.amount, transactions.original_balance_after_mutation.
- Importers (ING, Albert Heijn), the transaction split and receipt rewrite logic, budget and dashboard totals, charts.
- The MCP assistant tools and the JSON views.
- The production database, which the migration must convert without loss.

## Constraints

- Lossless: the migration converts each value to cents exactly, and aborts without changing data when any value has a fraction of a cent.
- The migration changes column types in place. It drops no column and no table. It never runs against production from an agent.
- No new gem. An own attribute type converts the form text to cents and back.
- Base on `origin/main`. The other agent's UI refactor branch does not exist (dropped 2026-10-16).
- `receipt_lines.quantity` stays decimal.
- The MCP tools and JSON views keep sending and accepting decimal amounts such as 12.50.
- Autonomous delivery (§7a). Approved permissions: type change in place. Not approved: dropping columns, new dependencies, deploys.

## In scope

- One migration that converts all listed columns to integer cents, with a safe rollback.
- Models, importers, calculations and views read and write cents.
- Forms accept and show 1,50 in the user's locale.
- MCP tools and JSON keep their decimal format.
- Tests for the conversion, including the migration on data with edge values.

## Out of scope

- Multiple currencies.
- Changing `receipt_lines.quantity`.
- Any UI redesign.
- Running the migration in production.

## Acceptance criteria

- A transaction stored as 1,5 shows as 1,50 after the migration and as 150 in the database.
- A user who types 1,50 in the transaction form gets 150 stored and sees 1,50 again.
- A user who types 1,5 or 1.50 gets the same result.
- A transaction of 12,34 split into 10,00 and 2,34 still sums to 12,34 and stays valid.
- A receipt with lines that add up to its total before the migration still adds up after it.
- Budget totals and dashboard balances show the same figures before and after the migration.
- The MCP tool for budget status still reports 12.50 for 1250 cents.
- The migration run on a copy of real data leaves every amount, rendered with two decimals, unchanged.
- Rolling the migration back restores the original decimal values.

## Open questions

None.
