# Plan: Store money as integer cents

From `intent.md` (2026-10-16). Status: accepted.

## Context

Ten money columns are `decimal` today. SQLite stores them with NUMERIC affinity, so most values sit on disk as REAL (floating point) and the rest as INTEGER. Rails reads them as `BigDecimal`. This change stores every money amount as a whole number of cents in an `integer` column, and makes Ruby code work in Integer cents. Users still type and read euros with two decimals. The MCP tools and the JSON view keep their decimal format.

Columns in scope: `appropriations.amount`, `budget_categories.amount`, `chattels.purchase_price`, `receipt_lines.full_amount`, `receipt_lines.discount_amount`, `receipt_lines.paid_amount`, `receipts.total_amount`, `transaction_splits.amount`, `transactions.amount`, `transactions.original_balance_after_mutation`. `receipt_lines.quantity` stays decimal.

Facts found on the development database (a copy of real data, 15 543 transactions), read-only:

- No value in any in-scope column has a fraction of a cent. The migration would not abort on this data.
- `transactions.original_balance_after_mutation` holds only whole euros. The ING importer assigns the raw CSV text (`"158,24"`) to a decimal column, and Rails reads that as `158`. The cents were always lost. 53 values are negative.
- `transactions.amount` holds 10 608 REAL and 4 935 INTEGER values.

## Design decisions

1. **Ruby works in Integer cents.** `transaction.amount` returns `150` for €1,50. Every sum, comparison and validation runs on Integers, so no arithmetic can create half a cent without an explicit rounding step. Rejected: a type that stores cents but hands Ruby a `BigDecimal` in euros. It touches less code, but it hides the arithmetic, and the intent requires that calculations read and write cents.
2. **`Cents` module** (`app/models/cents.rb`) holds the three conversions, so models, helpers, importers and tools share one rule:
   - `Cents.parse(text)` → Integer or `nil`. Strips surrounding whitespace. Accepts an optional leading minus. The last `,` or `.` followed by one or two digits is the decimal separator. Every other `,` or `.` is a thousands separator and must sit before a group of exactly three digits. Examples: `"1,50"`, `"1.50"`, `"1,5"` → `150`; `"12"` → `1200`; `"1.234,56"` and `"1,234.56"` → `123456`; `"-3,20"` → `-320`. Anything else returns `nil`: `"abc"`, `"1,2,3"`, `"12,34,56"`, `"1.2345"`, `""`.
   - A single separator followed by exactly three digits, with no other separator in the text (`"1.500"`, `"1,500"`), is ambiguous: €1,50 to an en user, €1 500 to an nl user. `Cents.parse` returns `nil` for it, so the form shows "is not an amount" instead of guessing. The user types `1500` or `1.500,00`. Unambiguous thousands groups still parse: `"1.234,56"`, `"1,234.56"`, `"1.234.567"`. ING amounts always carry two decimals, so the ING importer never meets the ambiguous form.
   - `Cents.from_euros(numeric)` → Integer. Converts through `BigDecimal(numeric.to_s)` so a Float such as `12.34` is exact. Raises `ArgumentError` when the result has a fraction of a cent.
   - `Cents.to_euros(cents)` → `BigDecimal` (`1250` → `12.5`), `nil` for `nil`.
3. **`Cents::Type`** (`app/models/cents/type.rb`, subclass of `ActiveModel::Type::Value`, `type` → `:integer`). `cast`: Integer stays Integer; String goes through `Cents.parse`; blank → `nil`; any other Numeric (Float, BigDecimal, Rational) raises `ArgumentError` that says to convert with `Cents.from_euros`. The raise is deliberate: an Integer `12` and a Float `12.0` must never mean different amounts silently. `serialize` and `deserialize` pass Integers through. No gem; no type registry entry, so no initializer references an autoloaded constant.
4. **`Monetary` concern** (`app/models/concerns/monetary.rb`) with the class macro `monetary :amount, ...`. Per attribute it declares `attribute name, Cents::Type.new` and a validation that adds `errors.add(name, :not_an_amount)` when the user gave non-blank text that `Cents.parse` could not read. Models that declare money: `Appropriation`, `BudgetCategory`, `Chattel`, `Receipt`, `ReceiptLine`, `TransactionSplit`, `Transaction` (`amount`, `original_balance_after_mutation`).
5. **`numericality` becomes `comparison`** on every money attribute. Rails' numericality validator checks the raw text the user typed, so `"1,50"` would fail as "is not a number" even though the type reads it. `comparison: { greater_than: 0 }` checks the cast Integer. The implementer proves this with a test that saves `"1,50"`.
6. **Display helper.** `MoneyHelper#cents_to_currency(cents, **options)` returns `number_to_currency(Cents.to_euros(cents), **options)`. It passes the same `BigDecimal` that `number_to_currency` gets today, so every rendered amount is identical. Every `number_to_currency` call in `app/` goes through it.
7. **Form value helper.** `MoneyHelper#cents_field_value(record, attribute, separator:)`. When the user typed text that failed validation, it returns that text unchanged, so the re-rendered form shows what the user typed. Otherwise it formats the cents with two decimals and the given separator, without a thousands delimiter. Text fields (`transactions/_form`, `chattels/_form`) pass the locale separator, `I18n.t("number.format.separator")`, so an nl user sees `1,50`. Number fields (`appropriations/_form`, `budgets/_budget_category_fields`, `transaction_splits/_table`) pass `"."`, because an HTML number input only accepts a dot; the browser shows it in the user's locale. Number fields always get two decimals, so `0.7` becomes `0.70`. This fixes the date-dependent failure of `BudgetsTest#test_suggesting_amounts_fills_in_historical_averages`.
8. **Charts stay in euros.** `ChartsHelper` prints axis labels and bar values. The dashboard view converts cents to euros with `Cents.to_euros(...).to_f` before it calls `svg_donut_chart`, `svg_bar_chart` and `svg_budget_chart`. `ChartsHelper` and `BudgetHelper` do not change: `BudgetHelper` only uses ratios. `ProductsHelper#chart_y` divides `price / highest`; with Integers that truncates, so it changes to `price.to_d / highest`.
9. **Dashboard and Budget compute in cents, exactly.** SQL sums return Integers. Every scaling step uses `Rational` instead of Float, and rounds once, to whole cents, at the end:
   - `Dashboard#months_in_range` returns `Rational(range_days, 30)`; `budget_amounts` returns `(budget_category.amount * months_in_range).round`.
   - `Dashboard#historical_averages` returns `(Rational(hist_sum, 365) * range_days).round` instead of Float euros with `.round(2)`.
   - `Dashboard#budget_actuals` uses `.to_i` instead of `.to_f`, so it returns Integer cents.
   - `Budget#suggested_amounts` divides with `Rational(total, lookback_days)` and returns `(... * period_days).round`; `suggestion_lookback_days` drops its `.to_f`.
   - `Rational#round` rounds half away from zero, as `number_to_currency`'s half-up does for positive and negative amounts. Each method's test asserts it returns Integers.
10. **MCP tools and JSON keep decimals.**
    - Inputs: `SetBudgetAmount` and `SetAppropriation` convert the JSON number with `Cents.from_euros`. A sub-cent amount (`12.345`) returns a `problem(...)` that says at most two decimals, instead of an exception.
    - Outputs: `BudgetStatus`, `ListAppropriations`, `SetBudgetAmount`, `SetAppropriation` and `ChargeToAppropriation` format `format("%.2f", Cents.to_euros(cents))`. `FindUncategorizedTransactions` prints `Cents.to_euros(transaction.amount)`, which keeps today's `12.5` text exactly. `BudgetStatus#describe` reads `budget_actuals` in cents and converts before it formats.
    - `transactions/_transaction.json.jbuilder` drops `:amount` from `extract!` and adds `json.amount Cents.to_euros(transaction.amount)`. It is the same `BigDecimal` as today, so the JSON is identical.
11. **Importers produce cents.**
    - `Importing::ING::Row` parses the amount with `Cents.parse(csv_row[6])`. It passes the balance text to the `monetary` attribute as today, so `Cents::Type` reads `"158,24"` as `15824`.
    - `Importing::AlbertHeijn::PackingSlip` wraps each `BigDecimal(...)` in `Cents.from_euros`, so `Line` and `total_amount` hold cents. `Line#paid_amount` stays a subtraction.
    - `Importing::AlbertHeijn::ImportJob` needs no change.
12. **`original_balance_after_mutation`** shows on `transactions/show` as `Cents.to_euros(...)`, which keeps today's text (`158.0`). The disabled text field on the transaction form uses `cents_field_value`. New imports now keep the cents of the bank balance (see Decision needed in Risks). Existing rows keep their whole-euro values, times 100.
13. **Search by amount.** `Transaction.search` matches `printf('%.2f', amount / 100.0) LIKE ?` instead of `CAST(amount AS TEXT) LIKE ?`. Every query that matched before still matches. A whole amount now also matches `"12.00"`.
14. **Transfer search.** `Linkable#searchable_transfers(amount:)` converts the text with `Cents.parse(amount)` instead of `amount.to_d`. A non-blank amount that does not parse returns `Transaction.none`, never `where(amount: nil)`. `suggested_transfers` compares Integers and does not change. `TransactionSplit#amount_does_not_exceed_balance` uses `amount_was.to_i` instead of `amount_was.to_d`.
15. **One schema migration**, `db/migrate/20261016120000_convert_money_to_cents.rb`, class `ConvertMoneyToCents < ActiveRecord::Migration[8.1]`. It uses SQL and the connection only, never a model.
    - `COLUMNS` lists the ten table/column pairs.
    - `up`, step 1, check: for every pair, `SELECT id, CAST(column AS TEXT) FROM table WHERE column IS NOT NULL`. Multiply each value by 100 as `BigDecimal`. Collect every row whose result has a fraction. When any exists, raise an error that names table, column and id for each, before any write. SQLite's text form of a REAL prints up to 17 significant digits, so float noise such as `0.30000000000000004` shows. A result within a millionth of a cent of a whole number counts as whole, so noise passes and a real half cent still aborts. (Departure found by the `up converts edge values` test.)
    - `up`, step 2, convert: `UPDATE table SET column = CAST(ROUND(column * 100) AS INTEGER) WHERE column IS NOT NULL`. Step 1 proved every value is a whole number of cents, so `ROUND` only removes float noise.
    - `up`, step 3, retype: `change_column table, column, :integer`, keeping `null: false` where it is today. `receipt_lines.discount_amount` gets `default: 0`.
    - `down`: `change_column` back to `decimal, precision: 10, scale: 2` (`original_balance_after_mutation`: plain `decimal`; `discount_amount`: `default: "0.0"`), then `UPDATE table SET column = CASE WHEN column % 100 = 0 THEN column / 100 ELSE column / 100.0 END WHERE column IS NOT NULL`. Whole euros return as INTEGER and the rest as REAL, which is how they were stored before.
    - Rails runs a SQLite migration in one transaction, so a failure at any step leaves the data as it was.
    - `db/schema.rb` is regenerated. Only the ten column lines and the schema version may change.
16. **Fixtures move to cents.** Every money value in `test/fixtures/*.yml` is multiplied by 100 (`amount: 75.00` → `amount: 7500`). Rails inserts fixtures without the model's attribute type, so a missed `75.00` would silently load as 75 cents. Two guards: `test/models/money_fixtures_test.rb` asserts one known value per money table in cents, and step 12's sweep greps the fixture files for a money key with a decimal point. Tests that build records with euro literals change to cents, or to text where the test is about user input.

## Integration points

- SQLite `change_column`: Rails copies the table to a new one. `transactions` is referenced by foreign keys from `chattels`, `receipts`, `transaction_splits` and `transaction_links`; Rails defers foreign keys during the copy.
- `number_to_currency` and the locale files (`config/locales/{en,nl,it}.yml`, `number.format.separator`, `number.currency`).
- ActiveModel attribute API and validators (`comparison`, `numericality`).
- MCP server (`gem "mcp"`) tool input schemas: unchanged (`type: "number"`).
- Kamal deploy: the production container runs pending migrations on boot. Out of scope here; see Risks.

## Files that change

New:

- `app/models/cents.rb` — `Cents.parse`, `Cents.from_euros`, `Cents.to_euros`.
- `app/models/cents/type.rb` — `Cents::Type`.
- `app/models/concerns/monetary.rb` — `monetary` macro and the unreadable-amount validation.
- `app/helpers/money_helper.rb` — `cents_to_currency`, `cents_field_value`.
- `db/migrate/20261016120000_convert_money_to_cents.rb` — the migration.
- `test/models/cents_test.rb`, `test/models/cents/type_test.rb`, `test/models/concerns/monetary_test.rb`, `test/models/money_fixtures_test.rb`, `test/helpers/money_helper_test.rb`, `test/migrations/convert_money_to_cents_test.rb`, `test/integration/transaction_amounts_test.rb`, `test/tools/assistant/budget_status_test.rb`.
- `docs/changes/cents-instead-of-decimals/verify/dump_before.rb`, `verify/dump_after.rb`, `verify/dump_raw.sql` — the real-data check scripts. They leave with the change folder at delivery.

Changed:

- `db/schema.rb` — ten columns become `integer`.
- Models: `appropriation.rb`, `budget_category.rb`, `chattel.rb`, `receipt.rb`, `receipt_line.rb`, `transaction_split.rb`, `transaction.rb` — `include Monetary`, `monetary ...`, `numericality` → `comparison`, search SQL, `amount_was.to_i`, return-type doc comments (`@return [Integer] cents`).
- `app/models/concerns/splittable.rb`, `linkable.rb` — doc comments to Integer cents; `Cents.parse` in `searchable_transfers`.
- `app/models/budget.rb` — `suggested_amounts` rounds to Integer cents.
- `app/models/dashboard.rb` — `budget_amounts` and `historical_averages` in Integer cents; doc comments.
- `app/models/importing/ing/row.rb`, `app/models/importing/albert_heijn/packing_slip.rb` — cents.
- Helpers: `products_helper.rb` (`to_d` division), `todos_helper.rb` (`cents_to_currency`).
- Views — every `number_to_currency` becomes `cents_to_currency`: `appropriations/{index,show,_balance}`, `budgets/show`, `chattels/_table`, `dashboard/_balance`, `product_types/show`, `products/{show,_price_chart}`, `receipts/{index,show,_basket}`, `searches/_result_transaction`, `shared/_recent_transactions`, `transaction_links/{_balance_table,_search_results,_suggestions}`, `transaction_splits/_table`, `transactions/{_table,show}`.
- Form fields get `value: cents_field_value(...)`: `appropriations/_form`, `budgets/_budget_category_fields`, `chattels/_form`, `transaction_splits/_table`, `transactions/_form`.
- `dashboard/index.html.erb` — chart data converted to euros.
- `transactions/_transaction.json.jbuilder` — `amount` in euros.
- MCP tools: `budget_status.rb`, `charge_to_appropriation.rb`, `find_uncategorized_transactions.rb`, `list_appropriations.rb`, `set_appropriation.rb`, `set_budget_amount.rb`.
- Locales `en.yml`, `nl.yml`, `it.yml` — `activerecord.errors.messages.not_an_amount` (en "is not an amount", nl "is geen bedrag", it "non è un importo"); then `bundle exec i18n-tasks normalize`.
- `test/fixtures/{appropriations,budget_categories,chattels,receipt_lines,receipts,transaction_splits,transactions}.yml` — values in cents.
- Existing tests that use euro literals for money, across `test/models`, `test/integration`, `test/helpers`, `test/jobs`, `test/tools`, `test/views`, `test/system` (56 files mention an amount; only those whose literals or expectations break change). `test/system/budgets_test.rb` formats the expected field value with `format("%.2f", Cents.to_euros(amount))`.

## Order of work

Each step ends with the narrowest test run green, then the step's test files. Commit after each step.

1. Write `test/migrations/convert_money_to_cents_test.rb` "up stores a transaction of 1,5 as 150 cents" (acceptance criterion 1, database half). Run it and watch it fail because the migration file does not exist.
2. Take the "before" snapshot while the app code is still `origin/main`'s (the branch holds only docs and one test file at this point). Copy the main checkout's development database into the worktree (`using-sqlite-worktrees` skill). Write `verify/dump_before.rb` and `verify/dump_raw.sql` (see Proof), run them, and keep `tmp/before.txt` and `tmp/raw_before.txt`. Do not commit `tmp/`.
3. Write `test/models/cents_test.rb`; build `app/models/cents.rb` until green.
4. Write `test/models/cents/type_test.rb`; build `Cents::Type` until green.
5. Write the migration. Make the step-1 test pass, then add the other migration tests (edge values, abort on a sub-cent value, abort after conversion, foreign keys intact, receipts still add up, rollback). Every migration test runs the migration through `ActiveRecord::Migrator`, so the DDL transaction applies as in a real `db:migrate`. Run `bin/rails db:migrate` on the worktree's development database and on the test database; check `db/schema.rb` changes only the ten columns.
6. Write `test/models/concerns/monetary_test.rb`; build `Monetary`. Convert the fixtures to cents. Declare `monetary` in the seven models, replace `numericality` with `comparison`, fix `amount_was.to_i`. Run `test/models` and fix model tests that use euro literals.
7. Write `test/helpers/money_helper_test.rb`; build `MoneyHelper`. Switch every view to `cents_to_currency` and every money field to `cents_field_value`. Add the locale key and normalize. Write `test/integration/transaction_amounts_test.rb` (criteria 1 display half, 2, 3) and the split test (criterion 4). Run `test/integration` and fix.
8. Dashboard, Budget, charts and `ProductsHelper`: Integer cents, euros only at the chart boundary. Run `test/models/dashboard_test.rb`, `test/models/budget_test.rb`, `test/helpers`, `test/integration/dashboard_test.rb`, `test/system/budgets_test.rb`.
9. Importers: ING and Albert Heijn. Run `test/models/importing`, `test/jobs/importing`, `test/integration/transactions_imports_test.rb`.
10. MCP tools and JSON. Write `test/tools/assistant/budget_status_test.rb` (criterion 7) and the input-conversion tests. Run `test/tools`, `test/integration/assistant_test.rb`.
11. Search and transfer links. Run `test/models/transaction_test.rb`, `test/integration/searches_test.rb`, `test/integration/transaction_links_test.rb`, `test/controllers/transaction_links_controller_test.rb`.
12. Sweep: `grep -rn "number_to_currency" app` must show only `MoneyHelper`; `grep -rnE "to_d\b|BigDecimal|\.round\(2\)" app` must show only intended uses. Full suite `bin/rails test` and `bin/rails test:system`, then `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check`, `bundle exec i18n-tasks normalize` (no diff).
13. Real-data check (criteria 6 and 8), below in Proof. Record the result in the pull request description.
14. Manual check in the browser on the worktree app (port 3001, copied database): type `1,50` in a transaction, a split, an appropriation and a budget amount; see `1,50` again.
15. JSON input (added after the implement report, coordinator decision): `TransactionsController` and `ChattelsController` convert a numeric JSON amount (`{"transaction":{"amount":12.5}}`) with `Cents.from_euros`, so it stores 1250. A sub-cent value answers 422 with an error message, never 500. Failing integration test first.

## Risks

- **Decision needed: new ING imports keep the balance's cents.** Today the importer stores `"158,24"` as `158`. With `Cents::Type` it stores `15824`, so the transaction page shows `158.24` for new imports while old rows keep `158.0`. The plan takes the correct reading. The alternative, truncating to whole euros on purpose, keeps a known bug.
- **Rails `change_column` on SQLite copies `transactions`** while four tables reference it. Rails defers foreign keys inside the migration transaction. The migration tests run up and down through the migrator, assert `PRAGMA foreign_key_check` is empty after each, and force a failure after the conversion to prove the transaction undoes it. The real-data run checks `PRAGMA foreign_key_check` too.
- **Validators read raw text.** Any `numericality` left on a money attribute rejects `"1,50"`. Step 12's sweep greps for `numericality` on money attributes.
- **Integer division.** `cents / something` truncates. Step 12 greps for `/` next to money names; `ProductsHelper#chart_y` is the known case.
- **Rounding moves from Float arithmetic plus half-up at display to exact `Rational` arithmetic rounded once to cents** in `Dashboard#budget_amounts`, `historical_averages` and `Budget#suggested_amounts`. A Float result that sat within float noise of half a cent could round differently. The real-data check compares dashboard figures for twelve months and shows any difference; a difference there stops the work and becomes a question for Etienne.
- **A non-Integer number assigned to a money attribute raises.** This is intended. Places that assign computed values (Budget suggestions, Receipt totals, PackingSlip) are covered by their tests.
- **Production migration runs on deploy.** Kamal boots the container, which runs `db:prepare`. Back up the production database before deploying this branch. No agent deploys it.
- **Schema dump noise.** Running migrations in the worktree can rewrite unrelated `db/schema.rb` lines. Only the ten column lines and the version are committed.
- **Search.** `printf('%.2f', ...)` is SQLite-specific, as `CAST(... AS TEXT)` is today. The app runs only on SQLite.
- Rejected: a `BigDecimal`-in-Ruby type (decision 1); new `*_cents` columns beside the old ones (the intent wants an in-place type change and no dropped columns); the `money-rails` gem (no new dependency).

## Out of scope

- Multiple currencies.
- `receipt_lines.quantity`.
- Any UI redesign, including changing number fields to text fields.
- Running the migration in production, and deploying.
- Repairing the whole-euro `original_balance_after_mutation` values already stored.
- Accepting a currency symbol (`€ 1,50`) in input.

## Proof

- A transaction stored as 1,5 shows as 1,50 after the migration and as 150 in the database → `test/migrations/convert_money_to_cents_test.rb` "up stores a transaction of 1,5 as 150 cents" and `test/integration/transaction_amounts_test.rb` "a transaction of 150 cents shows as 1,50"
- A user who types 1,50 in the transaction form gets 150 stored and sees 1,50 again → `test/integration/transaction_amounts_test.rb` "typing 1,50 stores 150 cents and the form shows 1,50 again"
- A user who types 1,5 or 1.50 gets the same result → `test/integration/transaction_amounts_test.rb` "typing 1,5 or 1.50 stores 150 cents"
- A transaction of 12,34 split into 10,00 and 2,34 still sums to 12,34 and stays valid → `test/integration/transaction_splits_test.rb` "splitting 12,34 into 10,00 and 2,34 leaves nothing unsplit"
- A receipt with lines that add up to its total before the migration still adds up after it → `test/migrations/convert_money_to_cents_test.rb` "receipt lines that add up to the total still do after up"
- Budget totals and dashboard balances show the same figures before and after the migration → `test/integration/dashboard_test.rb` and `test/integration/budgets_test.rb` existing figure assertions, green on cent fixtures; and check: the real-data comparison below, dashboard and budget section
- The MCP tool for budget status still reports 12.50 for 1250 cents → `test/tools/assistant/budget_status_test.rb` "reports a plan of 1250 cents as 12.50"
- The migration run on a copy of real data leaves every amount, rendered with two decimals, unchanged → check, in two parts:
  - Before (Order of work step 2, app code still `origin/main`'s, migration pending): `bin/rails runner docs/changes/cents-instead-of-decimals/verify/dump_before.rb > tmp/before.txt` writes every money value per table, column and id as `format("%.2f", value)`, then `number_to_currency` of every `Dashboard` figure (`debit_total`, `credit_total`, `profit_or_loss`, per-category totals, `budget_amounts`, `historical_averages`) for each of the last twelve calendar months, and each budget's allocations. `sqlite3 storage/db/development.sqlite3 < docs/changes/cents-instead-of-decimals/verify/dump_raw.sql > tmp/raw_before.txt` writes `table, column, id, typeof(value), CAST(value AS TEXT)` for every money value.
  - After (step 13, branch code): `bin/rails db:migrate`, then `bin/rails runner docs/changes/cents-instead-of-decimals/verify/dump_after.rb > tmp/after.txt` writes the same lines from cents, through `Cents.to_euros` and `cents_to_currency`. `diff tmp/before.txt tmp/after.txt` prints nothing. `sqlite3 storage/db/development.sqlite3 "PRAGMA foreign_key_check"` prints nothing.
- Rolling the migration back restores the original decimal values → `test/migrations/convert_money_to_cents_test.rb` "down restores the original decimal values"; and check: after the real-data run, `bin/rails db:rollback`, then `sqlite3 storage/db/development.sqlite3 < docs/changes/cents-instead-of-decimals/verify/dump_raw.sql > tmp/raw_after_rollback.txt`, and `diff tmp/raw_before.txt tmp/raw_after_rollback.txt` prints nothing. This raw dump needs no app code, so the branch's cent-based code cannot distort it. Migrate up again afterwards.

Per changed file, the unit tests expected:

- `app/models/cents.rb`: `Cents.parse reads 1,50 and 1.50 and 1,5 as 150`, `reads whole euros`, `reads thousands separators in both styles`, `reads a negative amount`, `returns nil for text that is not an amount`, `returns nil for a misplaced thousands separator`, `returns nil for an ambiguous 1.500 or 1,500`, `Cents.from_euros converts a Float exactly`, `refuses a fraction of a cent`, `Cents.to_euros returns BigDecimal euros`, `keeps nil`.
- `app/models/cents/type.rb`: `casts euro text to cents`, `keeps an Integer`, `casts blank to nil`, `refuses a Float or BigDecimal`.
- `app/models/concerns/monetary.rb`: `a record refuses text that is not an amount`, `a record accepts 1,50`.
- `db/migrate/20261016120000_convert_money_to_cents.rb`: `up stores a transaction of 1,5 as 150 cents`, `up converts every money column`, `up converts edge values` (0.01, 99999999.99, a negative balance, NULL, a REAL with float noise, an INTEGER-stored whole euro), `up aborts and changes nothing when a value has a fraction of a cent`, `up changes nothing when it fails after converting` (a test subclass of the migration raises in its last step), `foreign keys hold after up and after down`, `receipt lines that add up to the total still do after up`, `down restores the original decimal values`.
- `app/helpers/money_helper.rb`: `cents_to_currency renders 150 as it rendered 1.5`, `passes options through`, `keeps nil`, `cents_field_value formats with the locale separator`, `formats with a dot for number fields`, `returns the text a user typed after a failed save`.
- `app/models/transaction_split.rb`: `accepts an amount typed with a comma`, `refuses more than the balance in cents`.
- `app/models/receipt_line.rb`: `paid amount follows from the bonus in cents`.
- `app/models/budget.rb`: `suggested amounts are Integer cents`.
- `app/models/dashboard.rb`: `budget amounts are Integer cents scaled to the period`, `historical averages are Integer cents`, `budget actuals are Integer cents`.
- `app/models/transaction.rb`: `search finds a transaction by its amount in euros`.
- `app/models/concerns/linkable.rb`: `searchable transfers match an amount typed with a comma`, `searchable transfers return nothing for an unreadable amount`.
- `test/fixtures/*.yml`: `test/models/money_fixtures_test.rb` `fixtures hold money in cents` (one known value per money table).
- `app/models/importing/ing/row.rb`: `reads the amount as cents`, `reads the balance as cents`.
- `app/models/importing/albert_heijn/packing_slip.rb`: `reads lines and total as cents`.
- `app/helpers/products_helper.rb`: `plots Integer cents without truncating`.
- `app/tools/assistant/set_budget_amount.rb`, `set_appropriation.rb`: `stores 12.5 as 1250 cents`, `refuses an amount with a fraction of a cent`.
- `app/tools/assistant/find_uncategorized_transactions.rb`, `list_appropriations.rb`, `charge_to_appropriation.rb`: `reports amounts in euros as before`.
- `app/views/transactions/_transaction.json.jbuilder`: `renders the amount in euros as before`.

Test setup: fixtures hold cents. The migration test sets `self.use_transactional_tests = false`. It runs the migration through `ActiveRecord::Migrator` (with the connection pool's `schema_migration` and `internal_metadata`), never by calling `up` or `down` on an instance, so the DDL transaction applies. It migrates down in `setup`, inserts its rows with SQL, and in `teardown` deletes those rows and migrates up again when the columns are still decimal, so the worker's database ends at the current schema. The transaction amount tests sign in a user whose locale is `nl`. MCP tests call the tool classes directly with a `server_context`, as `test/tools/assistant/*_test.rb` already does.

---
Domain skills applied: rails-architecture, rails-testing, rails-ui, ruby-style, object-oriented-design.

## Critique

### Round 1 (codex exec -p terra)

- `Cents.parse` reads `"1.500"` as €1 500, while an en user typing it in a text field may mean €1,50 → fixed (decision 2 now refuses a lone separator followed by exactly three digits as ambiguous; unit test added)
- The integer-only claim does not hold: suggestions and dashboard scaling use Float, and `Dashboard#budget_actuals` keeps `.to_f` → fixed (decision 9 now uses `Rational` and rounds once to cents; `budget_actuals` uses `.to_i`; tests assert Integer results)
- `Linkable#searchable_transfers` turns an unreadable amount into `where(amount: nil)` → fixed (decision 14 returns `Transaction.none`; unit test added)
- Fixtures bypass the attribute type, so a missed `75.00` silently loads as 75 cents → fixed (decision 16 adds `test/models/money_fixtures_test.rb` and a fixture grep in the step 12 sweep)
- The "before" dump cannot run on branch code against a pending migration, and the verify scripts were not listed → fixed (new Order of work step 2 takes the before dump while the code is still `origin/main`'s; the rollback check uses a raw SQL dump; scripts listed under Files that change)
- The sub-cent abort test fails before any write, so it does not prove the migration transaction or foreign keys → fixed (tests run through `ActiveRecord::Migrator`, assert `PRAGMA foreign_key_check` after up and down, and force a failure after the conversion)
