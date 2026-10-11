# Intent: Shared payment-provider accounts

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-11). Type: bugfix. Delivery: autonomous.

## Problem

Payment providers such as Adyen, Mollie, Buckaroo, MultiSafepay, PAY.nl and Tikkie collect payments for many merchants on one bank account (IBAN). An ING import matches the counterparty on IBAN alone. Every payment through such an IBAN therefore lands on one external account, whatever the merchant.

Example: transaction 16642 has "Naam: Kruidvat" and IBAN NL04ADYB2017400157. It is booked on account 21 "Adyen", not on Kruidvat. Transaction 16567 ("Naam: Kirovanni/Foodticket", same IBAN) is booked on "Adyen" too.

The books cannot tell what was bought where. Per-merchant history, aliases and the merchant's default category do not apply to these payments.

## Proposed outcome

Etienne marks an external account as shared (a payment provider). For a shared account, the merchant name in the transaction decides the counterparty, not the IBAN. A separate action moves the existing transactions on a shared account to their merchants. The web app and the MCP assistant can both do this.

## Affected users and systems

- Family members who read and categorise transactions.
- The ING CSV import.
- External accounts, their aliases and their default category.
- The account page (marking an account as shared, moving existing transactions).
- The MCP assistant (new tools to mark and to move).

## Constraints

- Only an account Etienne marks as shared changes behaviour. AON has many name variants on one IBAN but is one company; it must stay as it is.
- A manually chosen category or a split on an existing transaction is never lost.
- Approved permissions for autonomous delivery: a migration that adds a column (nothing dropped or removed). Deploy files stay untouched. A new gem or package is not approved: stop and ask.

## In scope

- Mark and unmark an external account as shared, on the account page and through MCP.
- On import, a transaction to a shared IBAN books on the merchant named in the transaction.
- The merchant name drops a trailing "via …" or "by …" provider suffix: "Partydeco via Stichting Mollie Payments" becomes "Partydeco".
- The merchant resolves through the existing aliases and names first. No match creates a new external account with that name.
- A transaction with no usable merchant name stays on the shared account. Not usable: an empty name, or a name that is the shared account's own name or one of its aliases.
- A separate action ("move transactions to their merchants") on a shared account, on the account page and through MCP, moves existing transactions by the same rules.
- A moved transaction whose category is still the provider's default category gets the merchant's default category. Any other category and all splits stay.
- Unmarking an account affects new imports only. Moved transactions stay with their merchant.

## Out of scope

- Detecting shared accounts automatically.
- A fixed list of provider IBANs in code.
- Moving transactions back to the provider when unmarking.
- Imports other than ING (Albert Heijn packing slips).
- Renaming or cleaning up the provider account itself.

## Acceptance criteria

- With "Adyen" marked as shared, an imported transaction from IBAN NL04ADYB2017400157 with "Naam: Kruidvat" books on the existing Kruidvat account.
- With "Adyen" marked as shared, "Naam: Kirovanni/Foodticket" on that IBAN, with no matching account or alias, creates an external account "Kirovanni/Foodticket" and books on it.
- On a shared Mollie IBAN, "Naam: Partydeco via Stichting Mollie Payments" books on "Partydeco".
- On a shared Buckaroo IBAN, "Naam: Topbloemen by Buckaroo" books on "Topbloemen".
- On a shared Adyen IBAN, "Naam: Adyen" stays on "Adyen".
- A transaction to AON's IBAN still books on AON, because AON is not marked as shared.
- With "Adyen" newly marked as shared, transaction 16642 stays on "Adyen" until Etienne starts "move transactions to their merchants"; then it moves to Kruidvat.
- A moved transaction that had Adyen's default category gets Kruidvat's default category.
- A moved transaction that Etienne had categorised by hand as "Drogist" keeps "Drogist"; a split transaction keeps its splits.
- Starting the move twice moves nothing the second time.
- After Etienne unmarks "Adyen", a new import with "Naam: Kruidvat" books on "Adyen" again; transaction 16642 stays on Kruidvat.
- The assistant can mark "Adyen" as shared and start the move, with the same results as the web app.

## Open questions

None.
