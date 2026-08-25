# Phase 04 — Read the real invoice

Read `00-context.md` first.

## Why

Everything so far assumes a basket is already in the database. This phase is how a real one gets there:
an agent reads the Albert Heijn invoice mail through an email MCP server and hands the mail HTML to this
app, which parses it into a receipt, resolves the products, matches the payment and splits it.

## Blocked until this exists

**One real Albert Heijn invoice mail, saved as `test/fixtures/files/albert_heijn_invoice.html`.**

Do not invent Albert Heijn's markup and do not write the parser against a guess. Ask the owner for a real
mail. Remove only what identifies the household — name, address, customer number, delivery address, order
number if it is personal — and leave every line of product data exactly as sent, including the bonus
lines and the totals block.

If a second mail is available, save it too (`..._2.html`) and run the parser tests against both. One
sample teaches the parser one week's markup; two catch the parts that vary.

## Decide with the owner before starting

- Whether the mail carries the invoice PDF as an attachment or only a link into the Albert Heijn account.
  If it is only a link, decide whether the receipt keeps no PDF for now — the app cannot log in, and
  `Receipt#invoice` may simply stay empty.
- What the mail does with deposit, bag fee and delivery cost lines, once a real one is in hand. They are
  money on the invoice that is not a product, and the design leaves them out of the basket on purpose:
  the payment's remainder split absorbs them.
- Whether a weight-priced item (loose vegetables, cheese from the counter) appears with a weight as its
  quantity or as a pack size. That decides whether `quantity` or `pack_amount` carries the grams.

## Step 1 — The parser

### Tests first

`test/models/importing/albert_heijn/invoice_test.rb`, reading the saved mail with
`file_fixture("albert_heijn_invoice.html").read`:

| Test name | Asserts |
| --- | --- |
| `an invoice mail says when it was issued and what it came to` | the parsed invoice's date and total match the mail |
| `an invoice mail lists a line per product` | the number of lines matches the mail, and a named product's quantity, pack size, shelf price and paid amount match |
| `a bonus is folded into the line of the product it discounted` | the discounted product's line carries the discount, and no line exists for the bonus itself |
| `a line nobody discounted has no discount` | its discount is zero, not nothing |
| `mail that is not an Albert Heijn invoice is refused` | parsing an unrelated HTML string returns nothing rather than raising |

Write these one at a time against the real mail. Read the mail first and let it tell you the assertions;
do not write all five and then make them pass.

### Then

`app/models/importing/albert_heijn/invoice.rb`, mirroring the existing `Importing::ING::Row`: a value
object with a class-level `.parse` returning an instance or `nil`, `attr_reader`s for the parsed values,
and no knowledge of ActiveRecord. Lines come back as simple value objects too, one per product, each
carrying name, quantity, pack amount, pack unit, shelf amount, discount amount and paid amount.

Parse with Nokogiri, already in the bundle as a Rails dependency (1.19.4). Adding a parser gem needs the
owner's approval and should not be necessary.

Keep the arithmetic honest: if the mail states a paid amount, use it rather than recomputing it, and let
`ReceiptLine`'s own validation catch a line where paid is not shelf minus bonus. That validation exists
precisely to catch a parser that misread a column.

Commit: `feat(groceries): read an Albert Heijn invoice mail`.

## Step 2 — Importing a parsed invoice

### Tests first

`test/jobs/importing/albert_heijn/import_job_test.rb`:

| Test name | Asserts |
| --- | --- |
| `importing an invoice records the basket that was delivered` | a `Receipt` is created for the Albert Heijn account with the mail's date and total, and one line per product |
| `a product we have never bought before is created unclassified` | the new product exists and `unclassified?` is true |
| `a product we already know is reused` | importing a mail naming "AH Naturel Ribbelchips" does not create a second product |
| `the invoice is settled against its payment` | with a matching Debit present, the receipt's payment is set and the payment's splits follow the basket |
| `an invoice with no single matching payment is left unsettled` | no payment, no splits written |
| `importing the same invoice twice does not record it twice` | `Receipt.count` is unchanged on the second run, and the lines are not duplicated |
| `a basket costing more than the payment leaves the payment alone` | the payment keeps whatever splits it had |

### Then

`app/jobs/importing/albert_heijn/import_job.rb`, mirroring `Importing::ING::ImportJob`: thin, calling
into models.

1. Parse. Return early when the mail is not an invoice.
2. Resolve the shop through the existing `Resolvable` concern rather than a lookup of your own:
   `Account.resolve_for_import(account_number: nil, description: "", name: "Albert Heijn")`. With no
   account number and no description it falls through to the normalized-name branch, which is what
   already turns "Albert Heijn" into the known account and respects `AccountAlias`.
3. Find or build the receipt. "The same invoice" means the same shop, the same `issued_on` and the same
   `total_amount`; on a second import, replace that receipt's lines rather than adding a receipt.
4. Resolve each line's product by name, creating an unclassified one when unknown.
5. `receipt.payment = receipt.matching_payment` and then `receipt.rewrite_payment_splits`.

Also in this step: a migration adding a unique index on `LOWER(products.name)`. Resolve-by-name depends
on it, and it was deliberately left out until a caller needed it. Add the matching model validation at the
same time, so a duplicate shows an error instead of raising.

### Watch out

- `rewrite_payment_splits` returns `false` and writes nothing when the basket costs more than the payment.
  The import must not treat that as success. Record it somewhere the receipt page can show — the simplest
  honest option is that the receipt stays settled but unsplit, and the page says the basket does not fit.
  Decide with the owner before inventing a status column.
- Wrap the whole import in a transaction. A half-imported basket that already rewrote splits is worse than
  no import.
- Product names arrive with whatever spacing and casing the mail uses. Match case-insensitively on a
  stripped name; store the name as the mail wrote it.
- The first real import will create dozens of unclassified products and put them all on the todo page.
  That is correct.

Commit: `feat(groceries): import an invoice into a basket and split its payment`.

## Step 3 — The MCP tool

Depends on the app's `/mcp` endpoint, built on branch `ai/mcp-server` in `.worktrees/mcp-server`. If it
has not landed, stop after step 2 and report. Nothing else depends on this step.

### Tests first

| Test name | Asserts |
| --- | --- |
| `an agent can hand an invoice mail to the app` | calling the tool with the fixture mail creates the receipt and answers with what was imported and which payment it was matched to |
| `an agent without a valid token is refused` | the call is rejected and nothing is created |
| `handing over the same invoice twice changes nothing` | the second call reports the existing receipt |

### Then

Register one tool on the existing endpoint, taking the mail HTML as its only argument and calling the job
from step 2. Use whatever authentication that branch established — add no second scheme and no second
endpoint. The answer should be a sentence a person can read in a chat, naming the shop, the date, the
number of lines, the total, and either the payment it was settled against or that it is waiting.

Commit: `feat(groceries): let an agent hand an invoice to the app`.

## Files this phase touches

- `app/models/importing/albert_heijn/invoice.rb`
- `app/jobs/importing/albert_heijn/import_job.rb`
- `db/migrate/*_add_unique_index_to_products_name.rb`, `db/schema.rb`
- `app/models/product.rb` (uniqueness validation)
- `test/fixtures/files/albert_heijn_invoice.html`
- `test/models/importing/albert_heijn/invoice_test.rb`,
  `test/jobs/importing/albert_heijn/import_job_test.rb`
- Whatever file the `/mcp` branch uses to register tools — step 3 only

## Out of scope

- Fetching anything from Albert Heijn directly, including their app's undocumented interface.
- Reading mail from inside the app: no Action Mailbox, no IMAP polling, no mail credentials.
- A scheduled job that imports by itself. The agent decides when to hand something over.
- Guessing brands or product types from the parsed names.
- Importing from any other shop. The parser is Albert Heijn's markup only; a second shop is a second
  parser, later.
