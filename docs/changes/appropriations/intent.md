# Intent: Appropriations per purpose per budget year

Author: Etienne van Delden de la Haije. Status: accepted. Type: feature.

## Problem

Each year the family agrees how much it may spend per purpose: a birthday gift for each family member, Sinterklaas for each child, Christmas for each family member, and possibly other purposes. Each amount differs per purpose and per year, and is valid for that one calendar year only.

Today the books cannot record these amounts, nor charge a payment to one of them. The existing `Budget` answers "did we spend too much this month per category", not "how much of the 2026 birthday amount for Etienne is left".

The year a gift is paid and the year it is for often differ: a gift bought in 2026 can be for a birthday in 2027. Grouping payments by payment date gives the wrong answer.

## Proposed outcome

The household can set an appropriation (Dutch: begrotingspost) for any named purpose and recipient, per budget year, e.g. "Birthday Etienne 2026: €150", "Sinterklaas Chiara 2026: €75", "Birthday Grandma 2027: €40". The recipient is free text, not limited to family accounts.

A whole payment, or one split part of it, can be charged to an appropriation. One webshop order with gifts for two children can be split and each part charged to that child's appropriation.

The appropriation's budget year decides where a charge counts, not the payment date.

For each appropriation the household sees the amount appropriated, the amount charged, and the unexpended balance. At the end of its budget year an appropriation lapses: the unexpended balance does not carry over, and overspending simply shows as over.

Both the web app and the assistant (MCP endpoint) can set appropriations and charge payments to them.

## Affected users and systems

- Family members who keep the books, in the web app.
- The AI assistant filing transactions through `/mcp`.
- Existing transactions and their split parts (`TransactionSplit`), which gain a charge to an appropriation.
- English and Dutch translations; the Dutch term is "Begrotingspost".

## Constraints

- Usable within one to two weeks (by mid October 2026).
- Stands apart from the existing monthly `Budget`; its behaviour must not change.
- Charging to an appropriation must not break existing split rules (split total may not exceed the transaction amount; `Transfer` cannot be split).

## Open questions

None.
