# Intent: Albert Heijn products and product types from the mailbox

Author: Etienne van Delden. Status: accepted (2026-10-22). Type: feature. Delivery: autonomous. Codex review: yes

## Problem

Albert Heijn groceries reach the journal as one payment per delivery, so what was in the basket is lost. The app can read only one kind of Albert Heijn mail, the current "zijn ingepakt / komen eraan" packing slip. When it reads one, it creates each product knowing only its name. Brand and product type are filled in by hand, one product at a time. The mailbox holds about 175 Albert Heijn orders in three mail layouts (old "pakbon", current packing slip, order confirmation), and none of them is in the app. Albert Heijn's real invoices sit behind a login, so they cannot feed an automated job. As a result nobody can see which products the family buys, compare brands, or split a payment by what was bought.

## Proposed outcome

An agent reads the Albert Heijn basket mails and hands them to the app. Every order with a basket mail becomes a receipt with its lines. Every product on it exists with a name, a brand and a product type. Product types carry the accounting category their groceries book to. Deliveries that confidently match a bank payment are linked to it, and that payment's splits follow the basket. Products the agent is unsure about stay unclassified for a person to settle.

## Affected users and systems

- The household, who read the products, brands and spending per product type.
- `Product`, `ProductType`, `Receipt`, `ReceiptLine` and `Category`, and the payment splits of linked payments.
- The app's `/mcp` endpoint, which gets the tools an agent calls.
- The email MCP server and the agents that read the mailbox.
- Budgets, which see any category the agent creates.

## Constraints

- Albert Heijn is never contacted directly, and the app never reads mail itself. An agent reads the mail and hands it to the app.
- The agent makes the judgement calls (brand, type, category). The app only offers tools and checks.
- Importing is idempotent: an order is identified by its order number, and a mail that arrives twice updates the delivery instead of adding a second one.
- A brand or product type set by hand is never overwritten by an agent run.
- The existing guards stay: a basket costing more than its payment is refused, and a payment charged to an appropriation keeps its splits.
- Approved permissions for this change: additive migrations (never a drop or column removal), a new gem or package if a mail reader truly needs one, and edits to the MCP endpoint code.
- No deploy file changes. Deployment and the production run are out of scope.
- Verification runs the import and classification on a copy of the development database, with evidence recorded. The production run is a separate step that Etienne starts after merge and deploy.

## In scope

- Reading every mail layout that carries a basket: the current packing slip, the older "Alsjeblieft, hier is je pakbon" mails, and order confirmations for orders that have no packed-basket mail. A later packed-basket mail replaces an earlier confirmation of the same order.
- Orders from 2022-11 on.
- MCP tools on the app's endpoint that let an agent import a mail, create product types and categories, and set a product's brand and product type.
- Creating product types in Dutch shopping words (such as "Naturel chips") that group equal products across brands.
- Creating a new category under "Huishoudelijke uitgaven" when no existing category fits.
- Linking a delivery to its payment automatically when the bank note names the order number.
- Linking a delivery to its payment automatically when a door-card payment falls within 3 days of delivery, sits at most 15% under the mail total, and is the only candidate that fits.
- Listing every delivery that was not linked, so a person can confirm it.

## Out of scope

- Contacting Albert Heijn directly, or reading mail from inside the app.
- A scheduled import. The agent decides when to hand something over.
- Orders before 2022-11 (the 2016 to 2017 and 2021 mails).
- Non-grocery Albert Heijn orders (gift cards and tickets bought through deals.ah.nl).
- Pack size and price per unit.
- Any other shop.
- Changing the shop on existing transactions. That was fixed separately.
- Deploying, and running the import against production.

## Acceptance criteria

- Importing the current packing slip for a delivery records one receipt for its order number with one line per product, bonuses folded into their lines, and importing it again changes nothing.
- Importing an older "pakbon" mail, for example the one for the delivery of 2023-09-01, records a receipt whose products and total match the mail.
- An order with only a confirmation mail is recorded from that mail, and a packed-basket mail that arrives later replaces its lines.
- "AH Komkommer" ends up with brand "AH" and product type "Komkommer", booked to "Huishoudelijke uitgaven - Boodschappen".
- "AH Allesreiniger oceaan" ends up under a cleaning product type booked to "Huishoudelijke uitgaven - Huishoudelijk", not to Boodschappen.
- "AH Naturel chips" and another brand's naturel chips share the product type "Naturel chips".
- A product whose brand or type the agent cannot tell stays unclassified and appears on the unclassified list.
- A product whose brand and type were set by hand keeps them after a later agent run.
- When no existing category fits a product type, the agent creates one under "Huishoudelijke uitgaven" and the type uses it.
- The delivery of order 74532780 is linked to the 131.66 payment whose bank note names AE74532780, and the payment's splits follow the basket when it fits.
- A door-card payment within 3 days and 15% of a delivery's total, with two candidates that fit, is not linked and is listed instead.
- A payment already charged to an appropriation keeps its splits after its delivery is linked.
- A mail the reader cannot parse is skipped and reported, and nothing from it is saved.

## Flagged concerns

- The request bundles three changes that each ship and are useful alone: reading and importing baskets, classifying products, and linking payments. Etienne chose to keep them as one intent. The plan orders them as three stages, each shippable on its own, in that sequence.
- An agent may create categories. Budgets then see a category they did not have. Chosen side: the agent may create one, only under "Huishoudelijke uitgaven".
- The 3-day, 15% door-card link rests on inference, not on a number in the bank note, and it rewrites real payment splits. Chosen side: allowed, but only for a single fitting candidate, with every other delivery listed for a person.

## Decisions

- Do both the import and the classification in one job — no reason given.
- The agent decides, and products it is unsure about stay unclassified — no reason given.
- Read every order that has a basket mail, from 2022-11 on, and use the confirmation when there is no packed-basket mail — no reason given.
- The agent fills in brands as well as product types — no reason given.
- The agent may add categories — no reason given.
- Link deliveries to payments in this job, not in a separate one — no reason given.
- Confident enough to link means an order-number match, or a door-card match within 3 days and 15% — no reason given.
- Name the change by the slug ah-products-and-product-types, with no issue — no reason given.
- Deliver autonomously, with Codex review — no reason given.

## Open questions

None.
