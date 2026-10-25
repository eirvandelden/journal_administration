# Intent: MCP parity, slice 1: receipt to splits

Author: Etienne van Delden. Status: accepted. Type: feature. Delivery: autonomous. Codex review: no

## Problem

An assistant at `/mcp` cannot do what Etienne does in the UI for a grocery receipt. It cannot create, change or delete the splits of a payment. It cannot file a receipt with its lines, or classify the products on it. So Etienne cannot paste a receipt and have an agent file it, split the payment per category and charge the parts to appropriations. More broadly, the MCP covers 14 task-shaped tools and no CRUD per model, and nothing makes it follow new features.

## Proposed outcome

Etienne pastes a receipt into an assistant. The assistant files the receipt, links it to its bank payment, splits the payment per category and charges the parts to appropriations, with no UI step. For every model in this slice, the assistant can list, show, create, edit and delete whatever the UI lets Etienne list, show, create, edit and delete. A parity test and a written rule make the next feature ship its MCP tool in the same change.

## Affected users and systems

- Etienne and his wife, through any MCP client holding an assistant token.
- `AssistantController` and `app/tools/assistant/`.
- Models in this slice: Transaction, TransactionSplit, Receipt, ReceiptLine, Product, ProductType.
- Existing tools that already touch these models: `ChargeToAppropriation`, `SetTransactionCategory`, `FindUncategorizedTransactions`.
- `AGENTS.md` and this repository's change process.

## Constraints

- The assistant token stays a household-wide key; no per-user identity is added.
- The models keep their own rules: split total may not exceed the payment, a Transfer cannot be split, a charged payment cannot be re-split, a charged split cannot be dropped silently. A tool surfaces a refusal as a plain problem message and never works around it.
- Amounts are euros with two decimals at the tool boundary, as in the existing tools.
- No new gems or packages, no system tools, no dropping migrations, no deploy-file edits. Anything beyond that is a stop-and-ask.

## In scope

- Transactions: list or find, show, create, edit, delete, as the UI allows.
- Transaction splits: create, edit and delete one split at a time, and one atomic tool that replaces all splits of a payment (refused when any part is charged).
- Receipts: list, show, create with lines, delete, link and unlink the bank payment. A new receipt takes products by name (resolved like the importer does; unknown ones start unclassified). A receipt that matches an existing one by shop, issue date and total is refused, and the refusal names the existing receipt.
- Products: list, show, edit (brand, product type).
- Product types: list, show, create, edit, as the UI allows (no delete, as in the UI).
- A parity test: it fails when a routed UI resource has no MCP tool and is not on an explicit exclusion list.
- An `AGENTS.md` rule: a feature that adds or changes a model action ships its MCP tool in the same change.
- A parity line in this repository's plan and intent checklist.

## Out of scope

- Later slices: accounts, account aliases and transaction links; the gaps in categories, budgets and appropriations; chattels, people and groups.
- Users, assistant tokens, the admin area and the bank-file import.
- Attaching the invoice PDF to a receipt.
- Editing a receipt or its lines after filing (the UI cannot either; delete and file again).
- Changing the token model, host rules or authentication.

## Acceptance criteria

- Pasting a receipt makes the assistant file it with its lines, and the receipt shows the shop, the date, the total and each line.
- An assistant that links a receipt to its payment then splits the payment per category, and the splits add up to the basket.
- An assistant that splits a payment by 30.00 groceries and 12.50 household leaves a remainder split for the rest, as the UI does.
- An assistant that splits a payment for more than its amount is refused with the books' own reason.
- An assistant that splits a Transfer is refused.
- An assistant that replaces all splits of a payment with a charged part is refused, and nothing changes.
- An assistant that replaces all splits of an uncharged payment gets the new set in one step, or nothing at all.
- An assistant that files a receipt twice is refused the second time and told which receipt exists.
- A product named on a new receipt that nobody has seen before appears as an unclassified product.
- An assistant that classifies a product sets its brand and product type, and the product leaves the unclassified list.
- An assistant that deletes a transaction gets what the UI would give: the delete, or the books' refusal.
- A request without a valid assistant token, or from another host, is refused as today.
- A new routed UI resource with no MCP tool and no exclusion fails the parity test.

## Decisions

- Slice 1 is receipt-to-splits; the other models follow in later slices — the whole gap is too big for one change, and this slice covers the stated use case.
- Users and assistant tokens, the admin area and the bank-file import stay out of the MCP — chosen by Etienne; the token is a household key and a file upload does not fit a tool call.
- Delete stays allowed on money records — Etienne did not exclude it, and parity with the UI is the aim.
- A pasted receipt also creates a Receipt with its lines, not only splits — chosen by Etienne; the UI cannot do this today, so this goes beyond parity.
- Both single-split CRUD and an atomic replace-all tool — chosen by Etienne; the pair covers hand edits and whole-basket rewrites.
- A duplicate receipt is refused and the existing one named — recommended default accepted; it stops a double paste.
- The staying-in-step guard is a parity test, an `AGENTS.md` rule and a plan-checklist line — chosen by Etienne, all three.
- Autonomous delivery, no Codex review, no extra permissions — chosen by Etienne.

## Open questions

None.
