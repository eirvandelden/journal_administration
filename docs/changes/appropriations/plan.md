# Plan: Appropriations per purpose per budget year

From `intent.md` and `spec.md` (2026-09-28). Status: accepted; amendment 1 accepted.

Change folder: `docs/changes/appropriations/` in worktree `.worktrees/appropriations` (branch `appropriations`). This plan is copied there as `plan.md` once accepted.

## Context

The household agrees yearly amounts per purpose and recipient (birthday, Sinterklaas, Christmas, …). The books cannot record them or charge payments to them, and the year a gift is paid often differs from the year it is for. The existing monthly `Budget` answers a different question and must not change. Read `intent.md` and `spec.md` in the change folder for requirements R1–R18; this plan refers to them by number.

Approach: a new `Appropriation` model (purpose, recipient, budget_year, amount), and a nullable `appropriation_id` on both `transactions` and `transaction_splits`. A charge is that column, set or cleared through nested singular resources.

## Files that change

Data:
- `db/migrate/<ts>_create_appropriations.rb` — table `appropriations`: `purpose` string not null, `recipient` string not null, `budget_year` integer not null, `amount` decimal(10,2) not null; check constraint `amount > 0`; unique index on `LOWER(purpose), LOWER(recipient), budget_year` (same expression-index style as existing `LOWER(pattern)`/`LOWER(name)` indexes in `db/schema.rb`).
- `db/migrate/<ts>_add_appropriation_to_transactions_and_splits.rb` — nullable `appropriation_id`, foreign key and index on `transactions` and `transaction_splits`. No removal, no data change.
- `db/schema.rb` — regenerated.

Models:
- `app/models/appropriation.rb` (new) — validations R1/R2 (`uniqueness` case-insensitive scoped to purpose/recipient/year, so changing the year onto an existing one is also refused); `has_many :transactions` and `has_many :transaction_splits`, both `dependent: :restrict_with_error` (R4); `scope :of_year`; `scope :named` finding one appropriation by purpose, recipient and year ignoring letter case (used by the uniqueness check and the assistant's `set_appropriation`); `#charged` = charged Debit amounts + charged Debit-split amounts − the same for Credit, filtering on the `type` string and using `reorder`/`unscope(:order)` because `Transaction` has a `default_scope` order, worked out once per record (R11); `#balance`; `#overspent?`; `#charges` whole payments and split parts by payment date, undated ones last (R14); `#to_s` "Birthday Etienne 2026". The year totals for R13 are summed in the index view from the rows already loaded.
- `app/models/concerns/chargeable.rb` (new) — `belongs_to :appropriation, optional: true` for `Transaction` and `TransactionSplit`. No wrapper methods; callers use `update(appropriation:)`.
- `app/models/transaction.rb` — `include Chargeable`; `#charged?` (whole or any explicit part charged); validations, all checking the `type` string (after `update(type: "Transfer")` the object in memory is still a `Debit`): a Transfer cannot be charged (R8); a transaction with charged parts cannot become a Transfer; a transaction with explicit splits cannot be charged as a whole (R7).
- `app/models/transaction_split.rb` — `include Chargeable`; validations: a remainder split cannot be charged; a split cannot be added to a transaction charged as a whole, error on `:financial_transaction` so the existing split form shows it (R7). The Transfer case is already covered by `financial_transaction_must_not_be_transfer`. Delegates `booked_at` to its payment, so `Appropriation#charges` can sort whole payments and parts together.
- `app/models/receipt.rb` — `rewrite_payment_splits` returns `false` when `payment.charged?`. This covers the import job (`app/jobs/importing/albert_heijn/import_job.rb:30`), which re-imports without a person present.

Web app:
- `config/routes.rb` — `resources :appropriations`; under `resources :transactions`: `resource :appropriation_charge, only: %i[update destroy], module: :transactions`; under the nested `transaction_splits`: `resource :appropriation_charge, only: %i[update destroy], module: :transaction_splits`.
- `app/controllers/appropriations_controller.rb` (new) — index with `params[:year]` defaulting to `Date.current.year` (R13), show (R14), new/create/edit/update (R1–R3), destroy refusing with the model's error as alert (R4). YARD plus `@action`/`@route` tags on every action.
- `app/controllers/transactions/appropriation_charges_controller.rb` and `app/controllers/transaction_splits/appropriation_charges_controller.rb` (new) — `update` sets the appropriation (moves an existing charge, R10), `destroy` clears it; strong params `params.expect(appropriation_charge: [ :appropriation_id ])`; redirect to the transaction page, model errors as alert (R7, R8). Split lookup scoped to the transaction's explicit splits.
- `app/controllers/receipts/payment_links_controller.rb` — refuse before linking when `payment.charged?` (checked like `basket_fits?`), alert key `payment_is_charged`, so the receipt is not left linked.
- `app/views/appropriations/{index,show,new,edit,_form}.html.erb` (new) — index: year heading, previous/next year links, table purpose/recipient/appropriated/charged/balance, `<mark>` for overspent, totals row; show: charges table (date, or "-" when the payment has none; note; amount).
- `app/views/appropriations/_balance.html.erb` (new) — the balance, inside `<mark>` when overspent; used by index and show.
- `app/views/appropriations/_charge_form.html.erb` (new) — appropriation select plus "Charge" and, when charged, "Remove charge"; locals: `url:`, `chargeable:`.
- `app/views/transactions/show.html.erb` — for Debit/Credit: an "Appropriation" `dt/dd` with the current charge and charge form when not split; when split, the form next to each explicit part inside the existing split `<li>` list (R15). Nothing for Transfer (R8). The current charge and charge form live in `app/views/transactions/_appropriation.html.erb` (new), rendered for the whole payment and for each part.
- `app/helpers/appropriations_helper.rb` (new) — `grouped_appropriation_options(selected:)`.
- `app/views/layouts/application.html.erb` — nav entry `main_nav.appropriations` after budgets.
- `config/locales/{en,nl,it}.yml` — all new keys, including `activerecord.models/attributes.appropriation` and error messages under `activerecord.errors.models.{appropriation,transaction,transaction_split}` (restrict, R7 both ways, remainder, Transfer, become-Transfer). nl "Begrotingspost/Begrotingsposten", it "Stanziamento/Stanziamenti" (the i18n test requires every locale to hold every key). `bundle exec i18n-tasks normalize`.

Assistant:
- `app/tools/assistant/list_appropriations.rb` (new, read-only) — input `budget_year`; one line each: id, purpose, recipient, appropriated, charged, balance.
- `app/tools/assistant/set_appropriation.rb` (new, idempotent) — `purpose, recipient, budget_year, amount`; finds case-insensitively and changes the amount, or creates (R16).
- `app/tools/assistant/charge_to_appropriation.rb` (new, idempotent) — `appropriation_id, transaction_id`, optional `transaction_split_id`; refuses a split id of another transaction or a remainder split; charging a split transaction without a part answers with its explicit parts and their ids; other refusals are the model's errors.
- `app/controllers/assistant_controller.rb` — register the three tools.

## Order of work

1. Write the acceptance test "setting Birthday Etienne 2026 at €150 shows it on the 2026 page with €150 appropriated, €0 charged, €150 balance" in `test/integration/appropriations_test.rb`. Run it; watch it fail on the missing route. Walking skeleton: migration, model, route, controller create/index, minimal views, en/nl/it keys, until it passes.
2. `Appropriation` validation unit tests, then remaining appropriation-page acceptance tests (R1 zero, R2, R3, R13, R18) and nav entry.
3. Whole-payment charges: migration for `appropriation_id`, `Chargeable`, `Appropriation#charged/#balance/#overspent?` unit tests, transaction charge controller, charge form on show page (R5, R9, R10, R11, R15 unsplit).
4. Split-part charges: split charge controller, forms per part, R6, R7 both directions (the split refusal proven through the turbo_stream create response on the edit page), remainder refusal, R15 split.
5. Transfers (R8, including becoming a Transfer with charged parts), R4 removal, R14 charges list, R12, R17.
6. Receipts: `Transaction#charged?`, `rewrite_payment_splits` guard, payment-link refusal, import-job test.
7. Assistant tools one by one, acceptance test first (R16, R8 assistant half), then their unit-level refusals.
8. Full suite; `bundle exec rubocop`; `npx @herb-tools/linter app/views/`; brakeman; bundler-audit; `i18n-tasks normalize`. Re-read the diff. Run `bin/dev`, click through: create appropriation, charge a payment and a split part, open the 2027 page.

## Risks

- **Receipts rewrite splits.** `Receipt#rewrite_payment_splits` does `destroy_all` on the payment's splits; unguarded it drops charges silently, and it raises on a payment charged as a whole. Guarded in the model (covers the import job) and refused up front in `PaymentLinksController` so the receipt is not left linked. Decided with the user: refuse, do not re-attach.
- **Transaction type change.** The type is not recomputed once set (`determine_debit_credit_or_transfer_type` returns early), but the edit form permits `:type`. Validations on `Transaction` refuse Transfer while the transaction or any part is charged.
- **Destroying a split part removes its charge.** Accepted: the part no longer exists.
- **New transaction fixtures can shift existing tests** that count transactions, uncategorized ones, or dashboard totals. Give them a category (a gifts child category fixture) and fixed 2026 dates; run the full suite after adding them, before any feature code, and if existing tests shift, build those transactions inside the tests instead.
- **Default scope order** on `Transaction` would break grouped sums; sums use `reorder`/`unscope(:order)`.
- **Rejected: a separate polymorphic `appropriation_charges` table.** More joins and a model for no extra behaviour; one nullable column per chargeable row already means "at most one appropriation per amount".
- **Rejected: budget year as a date range.** The spec fixes one calendar year.
- **Rejected: charging the remainder split.** `Splittable#ensure_remainder_split` rebuilds it; the charge would vanish.

Out of scope: carry-over of balances; reports combining appropriations with the monthly budget; removing appropriations or charges via the assistant; linking recipients to accounts; JSON views for appropriations.

## Proof

- R1 set → `test/integration/appropriations_test.rb` `setting an appropriation shows it on its budget year's page with its full amount unspent`
- R1 zero → same file `an appropriation of nothing is refused`
- R2 → same file `a second appropriation for the same purpose, recipient and year is refused regardless of letter case`
- R3 → same file `raising an appropriation raises its balance by the same amount`
- R4 → same file `an appropriation without charges can be removed`
- R4 → same file `an appropriation with charges cannot be removed`
- R5 → `test/integration/appropriation_charges_test.rb` `charging a payment lowers the appropriation's balance by its amount`
- R6 → same file `the parts of one split payment can be charged to different appropriations`
- R7 → same file `a split payment cannot be charged as a whole`
- R7 → same file `a payment charged as a whole cannot be split`
- R8 web → same file `a transfer offers no charge`
- R8 assistant → `test/integration/assistant_test.rb` `the assistant cannot charge a transfer`
- R9 → `test/integration/appropriation_charges_test.rb` `a payment counts in the budget year of its appropriation, not the year it was paid`
- R10 move → same file `charging a payment to another appropriation moves its amount there`
- R10 remove → same file `removing a charge lowers the amount charged and keeps the payment`
- R11 refund → same file `a charged refund lowers the amount charged`
- R11 over → same file `spending more than appropriated shows a negative balance marked as overspent`
- R12 → `test/integration/appropriations_test.rb` `an unspent balance does not raise next year's appropriation`
- R13 → same file `the page shows this year's appropriations and totals unless another year is chosen` (`travel_to` a day in 2026)
- R14 → same file `an appropriation lists the payments and split parts charged to it`
- R15 → `test/integration/appropriation_charges_test.rb` `a payment's page shows its appropriation, per part when split`
- R16 list → `test/integration/assistant_test.rb` `the assistant lists a year's appropriations with what is left of each`
- R16 set → same file `the assistant sets an appropriation and changes its amount when set again`
- R16 charge → same file `the assistant charges a payment to an appropriation`
- R17 → `test/models/dashboard_test.rb` `charging a payment leaves its category and what it counts in the monthly budget unchanged`
- R18 → `test/integration/appropriations_test.rb` `in Dutch the page is called Begrotingsposten`
- Receipt guard → `test/integration/receipts_test.rb` `a receipt cannot be settled against a charged payment`; `test/jobs/importing/...` import job test `re-importing a charged payment's packing slip keeps its splits and charges`
- Added during review → `test/integration/appropriations_test.rb` `an appropriation lists a charged payment that has no booking date`, `a year that is not a number shows this year's appropriations`, `a year written with a leading zero is read as that year`, `the year page works out what is charged once per appropriation`; `test/integration/appropriation_charges_test.rb` `an uncharged payment's page proposes no appropriation`; `test/models/appropriation_test.rb` `#charges lists a payment without a booking date last`

Per changed file, the unit tests expected:
- `app/models/appropriation.rb` (`test/models/appropriation_test.rb`): `requires purpose, recipient, budget year and a positive amount`, `refuses a duplicate regardless of letter case`, `allows the same purpose and recipient in another year`, `refuses changing the year onto an existing purpose and recipient`, `#charged adds charged payments and split parts and subtracts refunds`, `#balance is appropriated minus charged`, `#overspent? when balance is negative`, `.of_year keeps only that year`, `cannot be destroyed while charged`, `#charges lists whole payments and split parts by payment date`.
- `app/models/transaction.rb` (`test/models/transaction_test.rb`): `a transfer cannot be charged`, `a split transaction cannot be charged as a whole`, `a charged transaction cannot become a transfer`, `a transaction with charged parts cannot become a transfer`, `#charged? when whole or any part is charged`.
- `app/models/transaction_split.rb` (`test/models/transaction_split_test.rb`): `a remainder split cannot be charged`, `a split cannot be added to a transaction charged as a whole`.
- `app/models/receipt.rb` (`test/models/receipt_test.rb`): `rewrite_payment_splits refuses a payment charged as a whole`, `refuses a payment with a charged part`.
- `app/helpers/appropriations_helper.rb` (`test/helpers/appropriations_helper_test.rb`): `groups appropriations by budget year, newest first, and marks the selected one`.
- Assistant tools (`test/integration/assistant_test.rb`): `listing a year without appropriations says so`, `charging a split payment without naming a part lists its parts`, `charging a part of another payment is refused`, `charging a remainder part is refused`, `charging to an unknown appropriation is refused`.

Test setup: new `test/fixtures/appropriations.yml` with literal years: `birthday_etienne` (2026, €150), `christmas_etienne` (2026, €100), `sinterklaas_chiara` and `sinterklaas_cosimo` (2026, €75), `christmas_serena` (2026, €50, never charged), `birthday_chiara_next_year` (2027, €60), `birthday_etienne_next_year` (2027, €150); it sets `created_at`/`updated_at` itself. New root category fixture `gifts`. New transaction fixtures on the `savings` account (on `checking` they pushed other fixtures out of its recent list): `gift_payment` (Debit €40, 2026-11-20), `large_gift_payment` (Debit €90), `gift_refund` (Credit €20), `webshop_sinterklaas` (Debit €100). Its €60/€40 split parts are created inside the tests that need them: as fixtures they changed the split row count in `transactions_index_test`. Nothing is charged in fixtures; each test charges what it needs. Shared row reader: `test/test_helpers/appropriation_assertions.rb`. The R1 acceptance test creates "Birthday Michelle 2026", because "Birthday Etienne 2026" is a fixture. Only R13 depends on today, so it uses `travel_to`. Integration tests sign in with `sign_in_as(users(:member))`; assistant tests use `ask_assistant`. No external boundaries to fake.

## Amendment 1 (2026-10-06): charge on the edit page, recipient suggestions

Status: accepted. Implements spec amendment 1 (R15 reworded, R19 added). Everything above stays as built; this section only lists what changes.

Files that change:
- `app/views/transactions/show.html.erb` and `app/views/transactions/_appropriation.html.erb` — show page only displays the current appropriation (name, linked to its page) for the whole payment or per split part; no form.
- `app/views/transactions/edit.html.erb` — for an unsplit Debit/Credit, `appropriations/_charge_form` for the whole payment, next to the split section. Nothing for Transfer.
- `app/views/transaction_splits/_table.html.erb` — new column with `appropriations/_charge_form` in each explicit part's row; none on the remainder row. The `create`/`update`/`destroy` turbo-stream responses re-render this table, so the column stays after split changes.
- `app/controllers/transactions/appropriation_charges_controller.rb` and `app/controllers/transaction_splits/appropriation_charges_controller.rb` — redirect to `edit_transaction_path` instead of the show page, success and refusal alike.
- `app/models/appropriation.rb` — `.recipient_suggestions`: household member names (`Account::FAMILY_OWNERS` without `samen`, humanized) plus distinct recipients already used, sorted, without duplicates ignoring letter case.
- `app/views/appropriations/_form.html.erb` — recipient text field gets `list:` pointing at a `<datalist>` of `Appropriation.recipient_suggestions`. No JavaScript.
- `config/locales/{en,nl,it}.yml` — keys for the new column header, if any.

Order of work:
1. Change the R15 acceptance tests in `test/integration/appropriation_charges_test.rb` to the three new R15 criteria; run; watch the edit-page ones fail (no charge select on the edit page) and the show-page one fail (a form is still there).
2. Move the forms and the redirects until they pass; existing charge tests that post to the charge routes keep passing, with redirect assertions changed to the edit page.
3. R19: model test for `.recipient_suggestions`, then the form datalist through the R19 acceptance test.
4. Full suite, rubocop, herb, brakeman, i18n-tasks normalize; re-read the diff; click through on the edit page with `DISABLE_SSL=1`.

Risks:
- The split table is rendered by turbo-stream responses as well as the edit page; a form inside each row must not break the existing split form or nest forms. `_charge_form` uses `button_to` for removal, which renders its own form, so it sits in a table cell, never inside the split form.
- `samen` is excluded by name; when #341 replaces the owner list with people, `.recipient_suggestions` moves to that model.

Proof:
- R15 show → `test/integration/appropriation_charges_test.rb` `a payment's page shows its appropriation, per part when split, without a way to change it`
- R15 whole → same file `charging an unsplit payment on its edit page makes it count there`
- R15 part → same file `charging one part on a split payment's edit page counts only that part`
- R19 → `test/integration/appropriations_test.rb` `the new-appropriation form suggests household members and earlier recipients`
- Added during review round 5 → `test/integration/appropriation_charges_test.rb` `a split payment's edit page offers no charge for the whole payment or its remainder`, `splitting a payment on its edit page stops offering to charge it as a whole`, `removing the last part on the edit page offers to charge the whole payment again`; `test/models/appropriation_test.rb` `.recipient_suggestions sorts ignoring letter case and keeps the latest spelling`. The whole-payment charge has its own section, `transactions/_whole_payment_charge.html.erb` (hidden for a transfer or a split payment), which the split turbo streams replace, so split changes update it. Round 6 added `splitting a transfer never offers to charge it`.
- `app/models/appropriation.rb` (`test/models/appropriation_test.rb`): `.recipient_suggestions lists household members but not the shared account`, `.recipient_suggestions adds earlier recipients once regardless of letter case`.

Test setup: existing fixtures; R19 tests create a "Grandma" appropriation inside the test.
