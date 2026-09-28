# Spec: Appropriations per purpose per budget year

From `intent.md` (2026-09-28). Status: accepted.

## Flagged concerns

- **Charging a split transaction as a whole.** A transaction can be charged whole, or per split part, not both at once: otherwise the same euro counts twice. Tradeoff: splitting a transaction that is already charged as a whole is refused until that charge is removed, which costs one extra step but keeps the charged totals right.
- **The remainder split.** The remainder split is rebuilt automatically whenever explicit splits change, so a charge on it would be lost silently. Only explicit split parts and whole transactions can be charged. To charge "the rest", make it an explicit split part first.

## Requirements

1. **R1 Set an appropriation.** The household can set an appropriation with a purpose (free text, e.g. "Birthday"), a recipient (free text, e.g. "Etienne", "Grandma"), a budget year (a calendar year) and an amount appropriated (more than zero).
2. **R2 One per purpose, recipient and year.** At most one appropriation exists per purpose, recipient and budget year, ignoring letter case.
3. **R3 Change an appropriation.** Its amount, purpose, recipient and budget year can be changed.
4. **R4 Remove an appropriation.** An appropriation without charges can be removed; one with charges is refused, naming why.
5. **R5 Charge a whole transaction.** A `Debit` or `Credit` without explicit split parts can be charged to one appropriation.
6. **R6 Charge a split part.** An explicit split part of a `Debit` or `Credit` can be charged to one appropriation. Different parts of one transaction can go to different appropriations.
7. **R7 No double charging.** A transaction that has explicit split parts cannot be charged as a whole, and a transaction charged as a whole cannot be split until the charge is removed.
8. **R8 Transfers cannot be charged.**
9. **R9 Charge any year.** A payment can be charged to an appropriation of any budget year, regardless of its payment date.
10. **R10 Move or remove a charge.** Charging something to another appropriation moves the charge. A charge can be removed; the transaction itself stays.
11. **R11 Totals.** Per appropriation: amount charged = charged `Debit` amounts minus charged `Credit` (refund) amounts; unexpended balance = amount appropriated minus amount charged. A negative balance shows as overspent.
12. **R12 Lapse.** Balances never carry over to another budget year.
13. **R13 Overview per budget year.** A page "Appropriations" (nl: "Begrotingsposten") lists the appropriations of one budget year, defaulting to the current year, with amount appropriated, charged and balance, plus the year's totals. Other years can be chosen.
14. **R14 Charges of one appropriation.** Opening an appropriation lists its charged transactions and split parts with payment date, note and amount.
15. **R15 Charge from the transaction page.** On a transaction's page the whole transaction, or each explicit split part, can be charged to an appropriation, and its current charge is shown.
16. **R16 Assistant.** Through `/mcp` the assistant can list a year's appropriations with their totals, set an appropriation (create, or change the amount of an existing one), and charge a transaction or split part to one.
17. **R17 Monthly budget unchanged.** Charges do not change a transaction's category or how the monthly `Budget` counts it.
18. **R18 Translations.** Every label exists in English and Dutch; the Dutch term is "Begrotingspost" / "Begrotingsposten".

## Design decisions

- **Household-wide.** Appropriations belong to the household, like `Budget`, not to one user.
- **Free-text purpose and recipient.** The intent allows any purpose and any recipient, so neither links to `Account` or `Category`.
- **Budget year as a year number**, not a date range: the intent says each appropriation is valid for exactly one calendar year.
- **Charging is separate from categorizing.** A gift still books to its category (e.g. "Gifts") for the monthly budget; the charge only answers "which appropriation does this count against".
- **Refunds count negative.** Chosen in the interview: a charged `Credit` lowers the amount charged.
- **Lapse means no carry-over only.** A late payment can still be charged to last year's appropriation (R9).
- **Removing an appropriation with charges is refused** rather than silently dropping those charges.
- **Assistant cannot remove appropriations or charges.** Destructive actions stay in the web app; moving a charge through the assistant is done by charging again (R10).

## Integration points

- `Transaction` (`Debit`, `Credit`, `Transfer`) and `TransactionSplit` including the `Splittable` remainder logic.
- Transaction show page and the split table partial (`app/views/transaction_splits/_table.html.erb`).
- Main navigation (new "Appropriations" entry).
- Assistant tools in `app/tools/assistant/` and `AssistantController`.
- Locale files (`en`, `nl`), normalized with `i18n-tasks`.

## Acceptance criteria

- **R1:** Setting "Birthday" for "Etienne" in 2026 at €150 shows it on the 2026 appropriations page with €150 appropriated, €0 charged and €150 balance.
- **R1:** Setting an appropriation of €0 is refused with a message that the amount must be more than zero.
- **R2:** Setting "birthday" for "etienne" in 2026 while "Birthday Etienne 2026" exists is refused with a message that it already exists.
- **R3:** Changing "Birthday Etienne 2026" from €150 to €200 shows €200 appropriated and the balance grows by €50.
- **R4:** Removing "Christmas Serena 2026" with no charges takes it off the page.
- **R4:** Removing "Birthday Etienne 2026" while a payment is charged to it is refused and the appropriation stays.
- **R5:** Charging a €40 payment to "Birthday Etienne 2026" shows €40 charged and €110 balance.
- **R6:** A €100 webshop payment split into €60 and €40, with the €60 part charged to "Sinterklaas Chiara 2026" and the €40 part to "Sinterklaas Cosimo 2026", shows €60 charged on Chiara's and €40 on Cosimo's.
- **R7:** Charging a split €100 payment as a whole is refused with a message to charge its parts instead.
- **R7:** Splitting a payment that is charged as a whole is refused with a message to remove the charge first.
- **R8:** A transfer offers no charge option in the web app, and the assistant is refused when it tries to charge one.
- **R9:** A payment made on 2026-11-20 charged to "Birthday Chiara 2027" counts on the 2027 page and not on the 2026 page.
- **R10:** Charging a payment already on "Birthday Etienne 2026" to "Christmas Etienne 2026" moves its amount from the first to the second.
- **R10:** Removing the charge of a payment lowers the appropriation's amount charged and the payment is still in the books.
- **R11:** "Birthday Etienne 2026" at €150 with a €90 payment and a €20 refund charged shows €70 charged and €80 balance.
- **R11:** "Birthday Etienne 2026" at €150 with €180 charged shows a balance of −€30 marked as overspent.
- **R12:** "Birthday Etienne 2026" with €30 balance left does not raise "Birthday Etienne 2027".
- **R13:** The appropriations page opened in 2026 without choosing a year shows the 2026 appropriations and their totals; choosing 2027 shows only the 2027 ones.
- **R14:** Opening "Sinterklaas Chiara 2026" lists the €60 split part with its payment date and note.
- **R15:** On a payment's page the current appropriation "Birthday Etienne 2026" is shown next to the payment, and next to each split part for a split payment.
- **R16:** The assistant asked for 2026 appropriations receives each one with amount appropriated, charged and balance.
- **R16:** The assistant setting "Christmas Michelle 2026" at €80 creates it; setting it again at €100 changes the amount to €100.
- **R16:** The assistant charging a payment to "Birthday Etienne 2026" makes it count there.
- **R17:** A €40 payment in category "Gifts" still counts €40 in the monthly budget for "Gifts" after it is charged to an appropriation.
- **R18:** With Dutch as the chosen language, the navigation and page title read "Begrotingsposten".

---
Domain skills applied: rails-architecture, rails-ui.
