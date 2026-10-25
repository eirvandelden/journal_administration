# Intent: Account page uses the shared transactions table

Author: Etienne van Delden. Status: accepted (2026-10-25). Type: feature. Delivery: autonomous. Codex review: no

## Problem

On an account page (`/accounts/XYZ`) the recent transactions table is a different, reduced table from the one on `/transactions`. It lacks the interest date column and the split sub-rows, so a user cannot work with the last transaction of an account from that page the way they can from the transactions list.

## Proposed outcome

The transactions table on an account page is the same table as on the transactions list, scoped to that account and paginated. Every table that lists transactions links each transaction's amount to that transaction, so a user reaches its show page, and from there its edit and delete pages, in one click.

## Affected users and systems

Household users on the account show page. The account page view and controller, the shared table partials, and the three transaction link tables (balance, suggestions, search results). The account edit page and the category pages use the same reduced table and are not part of this change.

## Constraints

- No new permissions: no gems, system tools, dropping migrations or deploy files.
- The transaction list keeps working unchanged.

## In scope

- Render the account page's transactions with the transactions table partial: same columns (including interest date), same split sub-rows, same amount link to the transaction.
- Keep pagination of the account's transactions on the account page.
- In the three transaction link tables, link each listed transaction's amount to that transaction.

## Out of scope

- The filters form (it submits to `/transactions`).
- A separate Show or Edit column: the amount stays the show link.
- The dashboard balance table (it lists categories, not transactions) and the transaction splits table (it lists splits of the transaction already on screen).
- The account edit page and the category pages.

## Acceptance criteria

- An account page lists the account's transactions with the same columns as the transactions list, including interest date.
- A split transaction on an account page shows its split sub-rows with amount, category and note.
- Clicking a transaction's amount on an account page opens that transaction, where Edit is available.
- An account with more than 20 transactions shows pagination on its page, and page 2 shows the next transactions.
- An account with no transactions shows an empty table without an error.
- On the transactions list, clicking an amount opens that transaction (already true; a test keeps it so).
- In the link suggestions, search results and balance table of a transaction, clicking an amount opens the linked transaction.

## Decisions

- Row access stays as on the index: amount links to the transaction, Edit lives on its show page — chosen from the options offered, no reason given.
- Filters are left out of the account page — filters submit to `/transactions`, so they do not fit here.
- Autonomous delivery, no Codex review, no extra permissions — chosen when offered.

- The amount is the show link everywhere; no extra Show button — "lets keep using the amount for the show link".
- Include the link, split and dashboard tables in the review of "all tables" — chosen when offered; on inspection the dashboard and splits tables list no transactions, so they stay unchanged.

## Open questions

None.
