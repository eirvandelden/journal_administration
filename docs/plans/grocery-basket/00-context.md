# Groceries: basket, prices and invoices — context for the executor

Read this file before any phase file. It is the whole context: what the feature is for, what already
exists, and the conventions the remaining work must follow.

## Why this feature exists

Groceries arrive from Albert Heijn every Friday and the invoice follows later that day. In the journal
the delivery is a single Debit transaction: one amount, one category. What was in the basket is lost.

The feature records the basket line by line so these questions can be answered:

- How much "naturel chips" do we buy?
- What did "AH Naturel Ribbelchips" cost in March compared to now?
- How often do we buy it on bonus, and how much did the bonus save?
- Which brand did we buy it from, and did the pack shrink?

## Design decisions already taken

These are settled. Do not revisit them without talking to the owner first.

- **A receipt is its own record, loosely coupled to the payment.** Invoice and payment arrive at
  different times, and a receipt total can differ from what the bank took (bag fee, deposit).
- **The shop is an `Account`.** Albert Heijn already exists there as the payment's creditor, and
  `AccountAlias` already resolves its name during import.
- **Product type is its own model, separate from `Category`.** `Category` is the accounting axis;
  product type is the shopping axis. A product type carries the accounting category its groceries are
  booked to.
- **The basket drives the payment's accounting splits.** Lines are grouped by their product type's
  category and written as one split each, so food versus household shows up in budgets by itself.
- **Every import re-derives the splits.** The basket is the source of truth for such a payment; hand
  edits on it do not survive a re-import.
- **A basket costing more than the payment is refused, never scaled.** Scaling would invent figures.
- **Three amounts per line**: shelf price, bonus, and what was paid. "Bought on bonus" is a line with
  a discount, so no extra flag exists. On the invoice a bonus is its own line naming its product; the
  parser folds it into that product's line.
- **Pack size is recorded per line as printed that week**, not only on the product, so a shrinking pack
  is visible.
- **Only what is needed now gets a table.** Brand is a plain string on the product; product types are
  flat with no parent; there is no product alias table. A brand table earns its place when a rename or
  a per-brand page hurts; a parent product type when "all chips" rollups are wanted; an alias table
  when Albert Heijn actually renames a product and a duplicate appears.
- **The invoice PDF lives on the receipt only**, and is reached from the payment through the link, so
  there is never a second copy to drift.
- **Albert Heijn is never contacted directly.** They have no public interface for personal orders; the
  undocumented app interface cannot be shown to carry delivered orders, may not carry the invoice PDF,
  and can break without notice. Instead an agent reads the invoice mail through an email MCP server and
  hands the mail HTML to this app. The app never reads mail itself.
- **No hand-entry form and no upload form.** The agent is how invoices get in.

## What already exists (branch `ai/grocery-basket`, five commits)

| Commit | What |
| --- | --- |
| `5e39a5a` | Product types and products |
| `d07e4ff` | Receipts and their lines, price per unit, bonus |
| `584cc82` | Matching a receipt to the payment that settled it |
| `2c7f5ff` | Splitting the payment the way the basket divides up |
| `f84df56` | The basket and the invoice link on the payment page |

### Tables

```
product_types   name (not null, unique on LOWER(name)), category_id (not null → categories)
products        name (not null), brand (string, nullable), product_type_id (nullable),
                pack_amount decimal(10,3), pack_unit integer
receipts        shop_id (not null → accounts), issued_on (not null), total_amount decimal(10,2)
                (not null), payment_id (nullable → transactions), invoice attached (PDF)
receipt_lines   receipt_id, product_id (both not null), quantity decimal(10,3) (not null),
                pack_amount decimal(10,3), pack_unit integer, full_amount decimal(10,2) (not null),
                discount_amount decimal(10,2) default 0 (not null), paid_amount decimal(10,2)
                (not null)
```

`pack_unit` is an integer enum defined once, in `Product::PACK_UNITS`:
`{ gram: 0, kilogram: 1, millilitre: 2, litre: 3, piece: 4 }`. `ReceiptLine` reuses it.

### Models and what they already do

- `ProductType` — belongs to a category, needs a name.
- `Product` — optional product type, brand as text, pack size. `#unclassified?` and
  `scope :unclassified` cover "brand or product type still missing".
- `Receipt` — `#basket_total` (sum of paid amounts), `#matching_payment` (a Debit to the same shop, for
  the receipt total, booked within `BOOKING_WINDOW` of seven days either side of the invoice date;
  returns nothing when two would fit), `#rewrite_payment_splits` (destroys the payment's splits, writes
  one per accounting category from the lines, then calls the existing `Splittable#ensure_remainder_split`
  so whatever the basket does not explain stays on the payment's own category; returns false and writes
  nothing when the basket costs more than the payment).
- `ReceiptLine` — `#on_bonus?`, `#comparable_unit` (kilogram, litre or piece), `#paid_price_per_unit`,
  `#shelf_price_per_unit`; refuses a line whose paid amount is not the shelf price minus the bonus.
- `Transaction` — `has_one :receipt, foreign_key: :payment_id, dependent: :nullify`.

### Views

`app/views/receipts/_basket.html.erb` renders the basket table (product, quantity, shelf price, bonus,
paid, price per unit, basket total, invoice link). It declares strict locals `(receipt:)` and is
rendered from `app/views/transactions/show.html.erb`. Reuse it; do not fork it.

### Test fixtures added

- `categories.yml` gained `household`.
- `product_types.yml`: `naturel_chips` (Groceries), `dishwashing_liquid` (Household).
- `products.yml`: `ah_ribbelchips`, `lays_ribbelchips` (both 300 g, type naturel_chips),
  `andrelon_shampoo` (deliberately unclassified — no brand, no type), `dreft_dishwashing_liquid`.
- `receipts.yml`: `albert_heijn_friday`, shop `albert_heijn`, total 50.00, issued the first of last
  month, which is when the `debit_grocery` transaction of 50.00 was booked.
- `receipt_lines.yml`: `ah_chips` (1.49), `lays_chips_on_bonus` (shelf 2.19, bonus 0.70, paid 1.49),
  `dreft` (3.49). Basket total is 6.47.

Existing tests: `test/models/product_test.rb`, `product_type_test.rb`, `receipt_test.rb`,
`receipt_line_test.rb`, `test/integration/payment_basket_test.rb`.

## Conventions this repo expects

- **Test first.** No production code without a failing test that fails for the right reason. Minitest
  with fixtures; no FactoryBot. Name each test as a sentence about the domain.
- **Rich models, no service objects.** Logic belongs on the object that owns the data. A parser is a
  value object, mirroring the existing `Importing::ING::Row` plus `Importing::ING::ImportJob` pair.
- **Guard clauses** (`return x if y`) over if/else when the line fits in 120 characters, followed by a
  blank line. Methods around 5 lines, under 10. Classes under 100 lines. At most 4 parameters.
- **Comments are a rare why.** Class-level docs are the local habit; do not restate signatures.
- **Every view string is translated in all three locales** — `en`, `nl`, `it` — in the same commit.
  `test/i18n_test.rb` fails otherwise. Locale keys are kept alphabetically sorted.
- **Linters must pass**: `bundle exec rubocop` and `bundle exec herb lint <files>`. Never add a disable
  comment. Partials need a `<%# locals: (...) %>` line or herb complains.
- **Commits**: conventional format with a scope, one logical change each, subject in domain language.
  The scope used so far is `feat(groceries): ...`. Never commit to `main`.
- **Money**: `decimal(10, 2)`. Quantities and pack sizes: `decimal(10, 3)`.

## How to run things

```
bin/rails test                        # whole suite
bin/rails test test/models/x_test.rb  # one file
bundle exec rubocop <files>
bundle exec herb lint <files>
bundle exec i18n-tasks normalize      # locale files must be normalized or test/i18n_test.rb fails
bin/rails db:migrate
```

The project runs on the Ruby named in `.ruby-version`. In a shell where `rv` does not resolve that
per directory, every command above needs the version put in front of it, or Bundler refuses to boot:

```
PATH="$HOME/.local/share/rv/rubies/ruby-4.0.6/bin:$PATH" bin/rails test
```

## Known state and traps

- **Work in a worktree.** The repository convention is that code-writing work happens in a worktree
  under `.worktrees/`, never in the main checkout. The branch for this work is `ai/grocery-basket`;
  create `.worktrees/grocery-basket` for it if it does not exist.
- **Another worktree, `.worktrees/mcp-server` on branch `ai/mcp-server`, is building the app's `/mcp`
  endpoint.** Phase 04's last step depends on it. Do not build a second MCP endpoint.
- The whole suite is green on this branch. Two `ChattelsControllerTest` failures that dogged earlier
  work came from an uncommitted `appkit` gem bump and were settled on `main` by
  `chore(deps): update appkit and mvpa.css to latest`; the branch has been rebased onto that.
- **Agent sandboxes** may refuse to read `.env` or `config/credentials.yml.enc` and to reach the
  1Password agent socket. Symptoms: the test runner claims `bin/rails` is a Bundler binstub, and
  `git commit` fails with "1Password: Could not connect to socket". Run tests and git outside the
  sandbox, and never write `config/credentials.yml.enc`.

## Out of scope for every phase

- Contacting Albert Heijn directly, in any form.
- A brand model, a parent product type, or a product alias table.
- Hand-entry or upload forms for baskets.
- Adding a charting dependency — the chart is hand-written inline SVG.
- Touching chattels. Chattels record `kind` and `model_number` but no brand; adding one is a separate
  branch and a separate pull request.
- Fixing the two failing chattels tests or committing the `Gemfile.lock` bump.
