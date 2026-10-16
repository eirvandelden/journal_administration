# Intent: One external account can hold several account numbers

Author: Etienne van Delden. Status: accepted. Type: feature. Delivery: step-by-step.

## Problem

Albert Heijn pays and is paid through three different account numbers, but it is one company.
An `Account` holds a single, unique `account_number`.
Each bank import that brings a new number creates a separate external Account.
Reports, budgets, search and receipts then treat one shop as three.
Today the only remedy is the name-based `AccountAlias` and the "absorb transactions" action, which moves transactions but not account numbers.

## Proposed outcome

One external account can carry several account numbers.
An import that brings any known number lands on that one account, with no duplicate appearing.
Existing duplicates, such as the three Albert Heijn accounts, can be merged into one account from the UI.
This works for any external account, not only Albert Heijn.

## Affected users and systems

- Household users who import and categorise bank transactions.
- Account matching during bank imports, and the account screens.
- Everything that points at an Account: transactions, receipts (`shop`), aliases, and the category an account books to.
- Global search, which searches `account_number`.

## Constraints

- Merging changes real data and is final after a confirm. It uses the native browser confirm and shows the counts first.
- A number may belong to one account only; uniqueness holds across all numbers.
- Household-owned accounts are not merged into external ones, or the reverse.
- Schema changes are additive. No table or column is dropped without explicit approval (playbook rule 9).
- The `Transfer` / `Debit` / `Credit` typing, which follows from family ownership, stays correct after a merge.
- Permissions: no gems or deploy files expected. The change adds a migration, which is approved only as additive.

## In scope

- Storing more than one account number on an external account, with uniqueness across all of them.
- Matching an imported number against all numbers of every account.
- An in-app merge action on the account page. That account is the target and survives, as with moving transactions through aliases today. The user picks the duplicates to merge into it. The action moves their transactions, receipts, aliases and numbers, then removes the emptied duplicates.
- Showing and editing the numbers on the account screen.
- Merging the three existing Albert Heijn accounts through that action.

## Out of scope

- Undoing a merge, or keeping merged accounts as inactive.
- Merging household-owned accounts.
- Matching by name beyond the existing `AccountAlias` behaviour.
- Suggesting or detecting likely duplicates automatically.

## Acceptance criteria

- Albert Heijn has three numbers on one account, and a transaction from any of the three shows under it.
- Importing a transaction from a known second number does not create a new account.
- Saving a number that already belongs to another account is refused with a clear message.
- Merging duplicates from an account page moves all their transactions, receipts and numbers to that account, and its totals add up.
- The target account keeps its own name. It keeps its own default category, or takes the first one from the duplicates when it has none.
- After a merge the emptied duplicate account no longer exists.
- Merging a household-owned account with an external one is refused.
- Merge asks for confirmation and states how many transactions and receipts move.
- Searching any one of the numbers finds the merged account.

## Flagged concerns

- Merge is final and touches real data, but undo is out of scope. The side chosen: a confirm that shows the counts, and no undo.

## Open questions

None.
