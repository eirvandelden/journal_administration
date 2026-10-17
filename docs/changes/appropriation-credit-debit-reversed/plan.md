# Plan: Appropriations treat credits as charges and debits as refunds

From `intent.md` (2026-10-17). Status: accepted.

## Design decisions

- One sign rule in one place. `Appropriation#charged` becomes `charged_on("Credit") - charged_on("Debit")`. `#balance`, `#overspent?`, the pages, `list_appropriations` and the transaction pages all read `#charged`, so nothing else computes the figure.
- `charged_on(type)` stays as it is. It already sums whole payments and split parts by the type of the parent transaction, so a split part of a credit counts like a whole credit without new code.
- Test data for charges is built in the test, not added as fixtures. New `Credit` fixtures in the `gifts` category would enter every dashboard, budget, import and transaction-list test that sums or counts transactions. The existing `bicycle_for_etienne` helper in `test/integration/appropriation_charges_test.rb` already builds a payment in the test; this plan generalises that pattern into one shared test helper.
- The existing `Debit` fixtures (`gift_payment`, `large_gift_payment`, `webshop_sinterklaas`) and the `Credit` fixture `gift_refund` stay unchanged. Tests whose figures do not depend on the sign (refusals, page links, "cannot be destroyed while charged", the dashboard test) keep using them.
- The charge list on the appropriation show page keeps showing each charge's stored, unsigned amount. The intent does not ask for signed rows, and the old page also showed refunds unsigned.
- Locale files need no change: no string in `config/locales/{en,nl,it}.yml` describes the charge direction. The wording that does is in doc comments and the two assistant tool descriptions.

## Integration points

- MCP tools `Assistant::ListAppropriations` and `Assistant::ChargeToAppropriation`: their `description` strings tell the assistant how charges count. The assistant reads these strings, so they must state the new direction.
- Views `appropriations/index`, `appropriations/show`, `appropriations/_balance`: unchanged; they read `#charged`, `#balance` and `#overspent?`.
- `Dashboard` and budgets: untouched. Charging never touches the category (`Chargeable`).

## Files that change

- `app/models/appropriation.rb` — `#charged` swaps the two `charged_on` calls. Its doc comment and the class comment say that credits, whole or in parts, are charged and debits are refunds.
- `app/tools/assistant/list_appropriations.rb` — the description says that charged counts credits minus debits, so a credit lowers the balance and a debit raises it.
- `app/tools/assistant/charge_to_appropriation.rb` — the description says that a charged credit lowers the balance and a charged debit, such as a returned item, raises it.
- `test/test_helpers/appropriation_payments.rb` (new) — module `AppropriationPayments` with `credit(amount, note:, on:)` and `debit(amount, note:, on:)`. Each creates a `Transaction` between `accounts(:savings)` and `accounts(:unknown)` in `categories(:gifts)`; the type follows from the accounts (`Credit`: creditor `savings`; `Debit`: debitor `savings`). `on` defaults to a 2026 time so the payment falls in budget year 2026. `test/test_helper.rb` does not load test helper modules, so every consumer adds `require_relative "../test_helpers/appropriation_payments"` and `include AppropriationPayments`, the way `AppropriationAssertions` is wired today. In `test/models/appropriation_test.rb` the nested `Totals` class includes it itself; it does not inherit from `AppropriationTest`.
- `test/test_helpers/appropriation_assertions.rb` — add `assert_appropriation_figures(charged, balance)`, which reads the show page's `dl` the way a person does: the charged and balance `dd` values next to their `dt` labels.
- `test/integration/appropriation_charges_test.rb` — new acceptance tests (see Proof). Existing tests that assert charged or balance figures switch from `Debit` fixtures to `credit(...)`, keep their figures, and get names that say "credit" where they said "payment": "charging a payment lowers the appropriation's balance by its amount", "the parts of one split payment can be charged to different appropriations", "a payment counts in the budget year of its appropriation", "charging a payment to another appropriation moves its amount there", "spending more than appropriated shows a negative balance marked as overspent", "charging an unsplit payment on its edit page makes it count there", "charging one part on a split payment's edit page counts only that part". "a charged refund lowers the amount charged" becomes "a charged debit lowers the amount charged" with a €90 credit and a €20 debit (charged €70, balance €80). `split_webshop_payment` gains a credit variant (or takes the payment as an argument) so split tests can split a credit of €100 into €60 and €40. `bicycle_for_etienne` becomes `credit(180, ...)`.
- `test/models/appropriation_test.rb` — `Totals`: "#charged adds charged payments and split parts and subtracts refunds" becomes "#charged adds charged credits and credit parts and subtracts debits", built from credits (€90 whole, €60 part) and one debit (€20) → €130. "#balance" uses a €40 credit → €110. "#overspent?" uses credits. `webshop_part` takes the payment to split. The `#charges` ordering tests keep the fixtures; order does not depend on sign.
- `test/tools/assistant/list_appropriations_test.rb` — a test that the line for a €200 appropriation with a €50 credit and a €20 debit reads charged `30.00` and left `170.00`.
- `test/integration/assistant_test.rb` — "the assistant lists a year's appropriations with what is left of each" charges a €40 credit instead of `gift_payment`, so its 150/40/110 figures stay. A new test reads `tools/list` and asserts that the `list_appropriations` and `charge_to_appropriation` descriptions state the credit/debit rule; tool calls never return descriptions, so only `tools/list` proves them.
- `test/data/migrate_people_groups_and_legacy_owners_test.rb` — "preserves household scopes and transaction types after migration" links a €40 debit (`gift_payment`) and a €60 part of a debit (`webshop_sinterklaas`) and checks charged €100 as a precondition. Its subject is the migration, not the sign, so it keeps its debit fixtures and expects `BigDecimal("-100")`: both links still count, now as refunds.

## Order of work

1. Add `test/test_helpers/appropriation_payments.rb`. Write the acceptance test for the first criterion in `test/integration/appropriation_charges_test.rb` (€200 appropriation, €50 credit → charged €50, balance €150). Run it and watch it fail on the figures (charged -€50, balance €250 today).
2. Write the acceptance tests for criteria 2, 3 and 4 in the same file. Run them; watch them fail on the figures.
3. Write the `list_appropriations` test for criterion 5. Run it; watch it fail.
4. Swap the sign in `Appropriation#charged`. Run the new tests; they pass.
5. Run `test/models/appropriation_test.rb`, `test/integration/appropriation_charges_test.rb`, `test/integration/appropriations_test.rb`, `test/integration/assistant_test.rb` and `test/data/migrate_people_groups_and_legacy_owners_test.rb`. Rewrite each test that now fails on the sign to use credits, as listed above. A test about the sign never gets its figures flipped without switching its payment type. The data-migration precondition is the one exception: its subject is the migration, so it asserts the new sign of the same debits.
6. Write the `tools/list` description test in `test/integration/assistant_test.rb`; run it and watch it fail. Update the two tool descriptions and the doc comments in `app/models/appropriation.rb`; the test passes.
7. Run `bin/rails test`, `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check` and `bundle exec i18n-tasks normalize` (expect no diff). All green.
8. Verify as a person would: run the worktree app locally, charge a credit and a debit to one appropriation and read the index and show pages; call `list_appropriations` through `/mcp` or the tool in `bin/rails runner`, and compare the figures.

## Risks

- Every existing link changes meaning at once (intent: no data migration). Real appropriations that were charged with debits now show negative charged amounts and a balance above the amount. This is the agreed behaviour; the plan does not soften it.
- A test rewritten by flipping only its expected figures would hide a wrong sign. Step 5 forbids that: tests switch payment type and keep figures.
- The charge list on the show page shows unsigned amounts, so a debit row looks like a charge. Accepted for now; a signed column would change agreed behaviour and is out of scope.
- Rejected: flipping the type of the shared fixtures (`gift_payment`, `webshop_sinterklaas`). They feed dashboard, transaction, person and data-migration tests.
- Rejected: adding new `Credit` fixtures in `gifts`. They would shift totals in unrelated dashboard and list tests.

## Proof

Each page criterion asserts the index row (`assert_appropriation_row`) and the show page (`assert_appropriation_figures`), since the intent names both pages.

- Linking a €50 credit to a €200 appropriation shows charged €50 and balance €150. → `test/integration/appropriation_charges_test.rb` `test "a charged credit lowers the balance by its amount"`
- Linking a €20 debit as well shows charged €30 and balance €170. → `test/integration/appropriation_charges_test.rb` `test "a charged debit raises the balance by its amount"`
- Linking only a €20 debit shows charged -€20 and balance €220. → `test/integration/appropriation_charges_test.rb` `test "a charged debit alone shows a negative amount charged"`
- A split part of a credit counts the same way as a whole credit. → `test/integration/appropriation_charges_test.rb` `test "a charged part of a credit counts like a whole credit"`
- The assistant's `list_appropriations` reports the same charged and balance figures as the pages. → `test/tools/assistant/list_appropriations_test.rb` `test "call reports charged as credits minus debits"`

Per changed file, the unit tests expected:

- `app/models/appropriation.rb`: `Appropriation#charged adds charged credits and credit parts and subtracts debits`, `#balance is appropriated minus charged`, `#overspent? when balance is negative`.
- `app/tools/assistant/list_appropriations.rb`: `call reports charged as credits minus debits`.
- `app/tools/assistant/list_appropriations.rb` and `app/tools/assistant/charge_to_appropriation.rb` descriptions: `test/integration/assistant_test.rb` `test "the appropriation tools describe credits as charges and debits as refunds"`, through `tools/list`.

Test setup: `appropriations(:birthday_etienne)` with its amount updated to €200 for the acceptance tests. Credits and debits come from `AppropriationPayments#credit` and `#debit`, created in the test between `accounts(:savings)` and `accounts(:unknown)` in `categories(:gifts)`, booked in 2026. Split parts are created on such a credit with `transaction_splits.create!`. No new fixtures, nothing faked.

## Out of scope

- Which transaction types may be linked to an appropriation.
- The monthly budget and dashboard.
- Double-entry bookkeeping.
- Stored transaction amounts, and a data migration.
- Signed amounts in the show page's charge list.

---
Domain skills applied: rails-architecture, rails-testing, ruby-style.

## Critique

### Round 1 (codex terra)

- The MCP description change has no proof: tool-call tests never see descriptions, only `tools/list` does. → fixed (added a `tools/list` test for both descriptions to Files, Order of work step 6 and Proof)
- The plan misses `test/data/migrate_people_groups_and_legacy_owners_test.rb`, whose precondition expects charged €100 from two debits and will read -€100. → fixed (added the file; it keeps its debit fixtures and asserts -€100, since its subject is the migration, not the sign)
  - Codex proposed dropping the precondition; keeping it with the new sign still proves both links count before the migration runs.
- The shared payment helper is not wired in: `test_helper.rb` does not load test helper modules, and the nested `Totals` class does not inherit includes. → fixed (each consumer requires and includes `AppropriationPayments`; `Totals` includes it itself)
- The automated Proof covers only the index page, while the intent names the show page too. → fixed (added `assert_appropriation_figures` for the show page; each page criterion asserts both pages)

Reproduction: committed
