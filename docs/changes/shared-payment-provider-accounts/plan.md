# Plan: Shared payment-provider accounts

From `intent.md` (2026-10-11). Status: accepted.

## Context

An ING import books every payment on the external account that owns the counterparty IBAN (`Resolvable.resolve_for_import` → `find_or_create_by(account_number:)`). Payment providers (Adyen, Mollie, Buckaroo, …) collect for many merchants on one IBAN, so all those payments land on the provider. This change lets a user mark an external account as a shared payment provider. For such an account, the merchant named in the transaction decides the counterparty, on import and through a separate "move transactions to their merchants" action. The web app and the MCP assistant both get both actions.

The merchant name sits in the ING "Mededelingen" column, stored as `transactions.original_note`, for example: `Naam: Kruidvat Omschrijving: … IBAN: NL04ADYB2017400157 Kenmerk: … Valutadatum: …`. Some rows have no `Omschrijving:` and continue straight with ` IBAN:`. Every provider payment seen in the data has this `Naam:` field.

## Design decisions

- **Column name `payment_provider`, not `shared`.** `accounts.payment_provider` (boolean, `default: false, null: false`). "Shared" already means the `samen` family account in this code (`Current.account`, fixtures `checking`). The UI text still says "shared payment provider", as the intent does.
- **Only external accounts can be marked.** `Account` validates that a payment provider has no owner. A family account is never a provider.
- **One source for the merchant name: the `Naam:` field of the description.** Import reads `row.description`; the move reads `transaction.original_note`. Both hold the same text, so import and move follow the same rules exactly. The CSV column "Naam / Omschrijving" (`row.initiator_name`) is not used for this: it is already rewritten through aliases in `Importing::ING::Row#initialize`, and it is not stored on the transaction, so the move could never use it.
- **Name extraction.** Take the text after `Naam: ` up to the next ING label (` Omschrijving:`, ` IBAN:`, ` Kenmerk:`, ` Machtiging ID:`, ` Datum/Tijd:`, ` Valutadatum:`) or the end of the text. Then drop a provider suffix: a ` via …` or ` by …` tail, case-insensitive, from the first such word onward ("PICNIC BY BUCKAROO" → "PICNIC"). Strip surrounding whitespace. No `Naam:` field means no usable name.
- **"Not usable" check.** A name is not usable when it is blank, or equals (case-insensitive, whitespace-stripped) the provider's own name or one of its alias patterns. The transaction then stays on the provider.
- **One alias rule for the provider.** Aliases keep their meaning everywhere else in the app: a pattern found inside a name points at its account, and the longest pattern wins (`find_by_alias`). So when the best alias match for a merchant name is one of the provider's own aliases, the name resolves to the provider and the payment stays there. Name lookup and account creation then never return the provider, because a name equal to the provider's name is already "not usable". A test covers a provider alias inside a longer merchant name, and a merchant alias longer than the provider's.
- **Merchant resolution is restricted to external accounts.** Order: `Account.external.find_by_alias(name)` (existing substring matcher), then an external account whose name equals the merchant name case-insensitively (`LOWER(name) = LOWER(?)`, as `absorb_transactions_for` compares, with an explicit `.order(:id).first` so duplicates resolve to the oldest), then create an external account with that name and no account number. Case-insensitive name match avoids "PICNIC" and "Picnic" becoming two accounts. A merchant name never resolves to a family account.
- **Category rule on a move.** A moved transaction gets the merchant's default category only when it has no explicit splits and its `category_id` equals the provider's `category_id`. This includes both being `nil`: an uncategorised transaction on an uncategorised provider still holds "the provider's default" and gets the merchant's default; nothing chosen by hand is lost. A split transaction keeps its parent category untouched, because `Splittable#ensure_remainder_split` copies the parent category onto the remainder split — changing it would change a split.
- **Move is per record, inside one database transaction.** Each moved transaction is saved with `save!`, so validations and the `after_save` remainder sync run. One failure rolls the whole move back. Volume is a few hundred rows per provider, so per-record saves are fine. `update_all` is rejected because it skips the category rule and validations.
- **Move saves and counts only real moves.** For each transaction on the provider, the move resolves the counterparty; when that is the provider itself, it skips the transaction without saving it (no timestamp change) and does not count it. So after one move, every transaction left on the provider is skipped, and a second move reports 0 and changes nothing. The proof uses a transaction that must stay (`Naam: Adyen`) next to one that moves.
- **Failures reach the user as a message, not a 500.** The move runs in one database transaction with `save!`, so a failure raises `ActiveRecord::RecordInvalid` and rolls back everything, including merchant accounts created during the move. `Accounts::MerchantReassignmentsController` rescues it and redirects with an alert; `Assistant::MoveTransactionsToMerchants` rescues it and answers with `problem(...)`. Both carry the record's error message.
- **Both directions.** A provider can be the debitor (an `Af` payment, booked `Credit`) or the creditor (a `Bij` refund, booked `Debit`). `move_counterparty` replaces whichever side held the provider; the STI type stays, because both sides remain external and `determine_debit_credit_or_transfer_type` derives the same type. On import, `assign_category_from_type` already reads the merchant's category from the correct side.
- **Move on an unmarked account moves nothing.** `counterparty_for` returns the account itself when it is not a provider. The web page shows the move button only for a provider; the MCP tool refuses with a message for a non-provider.
- **State as nested resources** (playbook: state transitions are nested resources):
  - `resource :payment_provider, only: %i[create destroy]` under `accounts` → `Accounts::PaymentProvidersController`. `create` marks, `destroy` unmarks.
  - `resource :merchant_reassignment, only: %i[create]` under `accounts` → `Accounts::MerchantReassignmentsController`. Mirrors the existing `transaction_absorption`.
- **Where the logic lives.** A new Account concern `PaymentProvider` (`app/models/concerns/payment_provider.rb`), in the style of `Normalizable`/`Resolvable`. It owns the validation, `counterparty_for(description)`, `move_transactions_to_merchants` and the private name parsing. The transaction side gets `Transaction#move_counterparty(from:, to:)` in the existing `Accountable` concern. No service object.
- **MCP tools.** `Assistant::SetPaymentProvider` (`set_payment_provider`; `account_id` integer, `shared` boolean) marks or unmarks. `Assistant::MoveTransactionsToMerchants` (`move_transactions_to_merchants`; `account_id`) runs the move and says how many moved. Both carry `annotations destructive_hint: true`, like `start_budget`. Register both in `AssistantController#tools`.
- **No authorization gate.** Every other account action (edit, aliases, absorption, bulk categorise) is open to any signed-in user; this one follows suit. The intent's "Etienne marks" names the user, not a role.

## Integration points

- `Importing::ING::ImportJob#perform` → `Account.resolve_for_import` (`app/models/concerns/resolvable.rb`). The account-number branch now returns `find_or_create_by(account_number:).counterparty_for(description)`.
- `Transaction.build_from_import` (`app/models/concerns/importable.rb`) is unchanged: it assigns the category from the counterparty it receives, so a merchant's default category applies automatically on import.
- `Normalizable.find_by_alias` is reused, scoped to `Account.external`.
- `Splittable` remainder sync (`after_save`) — see the category rule.
- `AssistantController#tools` — two new tools.
- Account show page (`app/views/accounts/show.html.erb`), inside the existing `if @account.external?` block.
- Locales `config/locales/en.yml`, `nl.yml`, `it.yml`; must stay normalised (`bundle exec i18n-tasks normalize`).
- `db/schema.rb` — the accounts table and the schema version only.

## Files that change

- `db/migrate/<timestamp>_add_payment_provider_to_accounts.rb` — new. `add_column :accounts, :payment_provider, :boolean, default: false, null: false`. Adds a column only (approved in the intent).
- `db/schema.rb` — the new column and version. Keep only that hunk.
- `app/models/concerns/payment_provider.rb` — new concern described above.
- `app/models/account.rb` — `include PaymentProvider`.
- `app/models/concerns/resolvable.rb` — account-number branch goes through `counterparty_for(description)`; update its doc comment.
- `app/models/concerns/accountable.rb` — `move_counterparty(from:, to:)` plus a private predicate for the category rule; update the module comment, which today says it only holds predicates.
- `app/controllers/accounts/payment_providers_controller.rb` — new; `create` and `destroy`, redirect to the account with a notice, or an alert with the validation message.
- `app/controllers/accounts/merchant_reassignments_controller.rb` — new; `create` runs the move and redirects with a count notice.
- `config/routes.rb` — the two nested singular resources under `accounts`.
- `app/views/accounts/show.html.erb` — in the external block: a line saying whether the account is a shared payment provider, a mark/unmark `button_to`, and, for a provider only, the "Move transactions to their merchants" `button_to` with a `turbo_confirm`.
- `app/tools/assistant/set_payment_provider.rb`, `app/tools/assistant/move_transactions_to_merchants.rb` — new tools.
- `app/controllers/assistant_controller.rb` — register both tools (alphabetical order, as now).
- `config/locales/en.yml`, `nl.yml`, `it.yml` — `accounts.show.*` labels and buttons, `payment_providers.create/destroy.success`, `merchant_reassignments.create.success` (with `count`), the validation message `activerecord.errors.models.account.attributes.payment_provider.must_be_external`.
- `test/fixtures/accounts.yml` — `adyen` (name "Adyen", account_number `NL04ADYB2017400157`, category `gifts`, not a provider) and `aon` (name "AON CCSI", account_number `NL69ABNA0244748942`).
- `test/fixtures/transactions.yml` — payments on `adyen` (Credit, debitor `adyen`, creditor `checking`, as real ING imports book them): `kruidvat_through_adyen` (category `gifts`, original_note `Naam: Kruidvat Omschrijving: … IBAN: NL04ADYB2017400157 …`), `hand_categorised_through_adyen` (Kruidvat merchant, category `bakery`), `adyen_itself` (`Naam: Adyen …`), and `refund_through_adyen` (Debit, debitor `checking`, creditor `adyen`, category `gifts`, `Naam: Kruidvat …`).
- Tests listed under Proof.

## Order of work

Worktree gotchas (from `AGENTS.md`): put this worktree's `bin/` first on `PATH` before running `bin/rails`; run `yarn install` once here before pushing, or the herb pre-push hook fails.

1. Add the `adyen` account fixture (without the new column). Write the acceptance test "a payment through a shared provider books on the merchant's existing account" in `test/jobs/importing/ing/import_job_test.rb`: mark `adyen` with `update!(payment_provider: true)`, import a row for IBAN `NL04ADYB2017400157` with description `Naam: Kruidvat Omschrijving: … IBAN: NL04ADYB2017400157 …`, assert the new transaction's debitor is `accounts(:kruidvat)`. Run it; watch it fail (unknown attribute `payment_provider`).
2. Add the migration. Get a development database here by copying the main checkout's one (`using-sqlite-worktrees` skill), then run `bin/rails db:migrate`. Keep only the accounts hunk and version in `db/schema.rb`. Rerun the test; it now fails because the transaction books on Adyen.
3. Unit-test and build `PaymentProvider` name parsing and `counterparty_for` in `test/models/concerns/payment_provider_test.rb`, red/green per behaviour. Then wire `Resolvable`. Step 1's test goes green.
4. Add the remaining import acceptance tests (Kirovanni creates an account, Mollie `via`, Buckaroo `by`, `Naam: Adyen` stays, AON unchanged, unmarked provider books on itself). Green them.
5. Unit-test and build `Transaction#move_counterparty` (`test/models/concerns/accountable_test.rb`) and `Account#move_transactions_to_merchants` (`payment_provider_test.rb`).
6. Write the web acceptance tests (`test/integration/payment_providers_test.rb`, `test/integration/merchant_reassignments_test.rb`); add routes, controllers, view and locales until green. Run `bundle exec i18n-tasks normalize`.
7. Write the assistant acceptance tests in `test/integration/assistant_test.rb`; add the two tools and register them.
8. Full suite, `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check`. Re-read the diff.
9. Verify as a human (playbook rule 22): run the app from this worktree on port 3001 with the copied dev database, mark a provider account with mixed merchants, move, check the account pages. Record what was seen.

## Risks

- **Over-eager suffix stripping.** A merchant whose real name contains " by " or " via " ("Stand by Me") gets cut. The intent asks to drop any trailing "via …"/"by …" provider suffix, and the provider's account name does not reliably name the provider in that suffix (Adyen's IBAN account was first named after a merchant; Buckaroo's is "STICHTING DERDENGELDEN BUCKAROO" while the suffix says "Buckaroo"). So the strip is not tied to the provider's name. Only accounts marked as a provider are affected, and the result is still a separate merchant account. Accepted.
- **Name-label list misses a label.** An unknown ING label after the name would end up inside the merchant name. The capture also stops at the end of text, so the worst case is a long account name on one payment; a user can alias or absorb it. The labels come from the real notes in the development database.
- **Duplicate merchant accounts from concurrent uploads.** `Transactions::ImportsController#create` runs `ImportJob.perform_now` row by row, so one upload is sequential. Two uploads at the same moment, or an upload during a move, could both create the same new merchant. The existing name-based resolution has the same race, and the absorb action already merges such duplicates. Accepted; no unique index on names, because existing data already holds duplicate external names.
- **New fixtures shift other tests.** Two extra external accounts and three transactions can change counts, search results or totals elsewhere (pagination, searches, budget status, dashboards). Run the full suite after step 1 and adjust only the new fixtures' data (for example dates) — never another test's assertion.
- **Remainder split.** Changing a split transaction's category would rewrite its remainder split. The category rule skips split transactions for this reason.
- **Schema dump noise.** Migrating a copied development database may reorder or re-dump unrelated parts of `db/schema.rb`. Commit only the accounts hunk and version.
- Rejected: a fixed list of provider IBANs (out of scope); automatic detection (out of scope); a `shared` column name (clashes with `samen`); `update_all` for the move (skips the category rule and validations); a checkbox on the edit form instead of a nested resource (playbook prefers state as resources, and it keeps `account_params` unchanged).

## Out of scope

- Detecting providers automatically, or a built-in list of provider IBANs.
- Moving transactions back to the provider when unmarking.
- Imports other than ING (Albert Heijn packing slips).
- Renaming or cleaning up provider accounts, or merging existing per-merchant provider accounts such as "HEMA by Adyen".
- Changing `FindAccounts` output or any other existing MCP tool.

## Proof

- With "Adyen" shared, `Naam: Kruidvat` on `NL04ADYB2017400157` books on Kruidvat → `test/jobs/importing/ing/import_job_test.rb` `a payment through a shared provider books on the merchant's existing account`
- With "Adyen" shared, `Naam: Kirovanni/Foodticket` creates and books on a new external account → `test/jobs/importing/ing/import_job_test.rb` `a payment through a shared provider to an unknown merchant creates that merchant`
- Shared Mollie IBAN, `Naam: Partydeco via Stichting Mollie Payments` books on "Partydeco" → `test/jobs/importing/ing/import_job_test.rb` `a via suffix is dropped from the merchant name`
- Shared Buckaroo IBAN, `Naam: Topbloemen by Buckaroo` books on "Topbloemen" → `test/jobs/importing/ing/import_job_test.rb` `a by suffix is dropped from the merchant name`
- Shared Adyen IBAN, `Naam: Adyen` stays on Adyen → `test/jobs/importing/ing/import_job_test.rb` `a payment naming the provider itself stays on the provider`
- (supporting) A `Bij` refund through shared Adyen books on Kruidvat as a Debit → `test/jobs/importing/ing/import_job_test.rb` `a refund through a shared provider books on the merchant`
- AON's IBAN still books on AON → `test/jobs/importing/ing/import_job_test.rb` `a payment to an account that is not a shared provider books on that account`
- Newly shared Adyen: transaction stays until the move, then moves to Kruidvat → `test/integration/merchant_reassignments_test.rb` `marking a provider leaves its transactions until they are moved`
- Moved transaction with Adyen's default category gets Kruidvat's default → `test/integration/merchant_reassignments_test.rb` `a moved transaction with the provider's default category gets the merchant's default`
- Hand-picked category and splits are kept → `test/integration/merchant_reassignments_test.rb` `a moved transaction keeps a category chosen by hand` and `a moved split transaction keeps its splits`
- Moving twice moves nothing the second time → `test/integration/merchant_reassignments_test.rb` `moving a second time moves nothing`
- After unmarking, a new import books on Adyen and moved transactions stay → `test/integration/payment_providers_test.rb` `unmarking a provider books new imports on it and leaves moved transactions`
- The assistant marks Adyen and starts the move with the same results → `test/integration/assistant_test.rb` `the assistant marks a shared provider and moves its transactions to their merchants`

Per changed file, the unit tests expected, named as behaviour:

- `app/models/concerns/payment_provider.rb` (`test/models/concerns/payment_provider_test.rb`): `a family account cannot be a payment provider`; `counterparty_for returns the account itself when it is not a provider`; `counterparty_for reads the merchant up to the next ING label`; `counterparty_for reads a merchant followed directly by IBAN`; `counterparty_for drops a via or by suffix in any case`; `counterparty_for stays on the provider without a Naam field`; `counterparty_for stays on the provider for its own name or an alias, in any case`; `counterparty_for stays on the provider for a name left empty by the suffix`; `counterparty_for prefers an alias over a name match`; `counterparty_for stays on the provider when its own alias is the best match inside a longer name`; `counterparty_for picks the merchant when the merchant's alias is longer than the provider's`; `counterparty_for picks the oldest of two external accounts with the same name`; `counterparty_for matches an existing name case-insensitively`; `counterparty_for never resolves to a family account`; `move_transactions_to_merchants returns how many moved`; `move_transactions_to_merchants leaves a staying transaction unsaved`; `move_transactions_to_merchants moves nothing on an unmarked account`; `move_transactions_to_merchants rolls back every move when one fails` (an earlier transaction creates a new merchant, a later `save!` is forced to fail; assert no new account, no changed counterparty, category or split remains).
- `app/models/concerns/resolvable.rb` (`test/models/concerns/resolvable_test.rb`): `resolve_for_import books a provider payment on its merchant`.
- `app/models/concerns/accountable.rb` (`test/models/concerns/accountable_test.rb`): `move_counterparty replaces the debitor or the creditor that was the old account, keeping the type`; `move_counterparty gives the new default category when the old default was kept`; `move_counterparty gives the new default to an uncategorised transaction of an uncategorised provider`; `move_counterparty keeps any other category`; `move_counterparty keeps a split transaction's category and splits`.
- `app/controllers/accounts/payment_providers_controller.rb` (`test/integration/payment_providers_test.rb`): `marks an external account as a shared provider`; `refuses to mark a family account`; `unmarks a provider`; `redirects to login when signed out`.
- `app/controllers/accounts/merchant_reassignments_controller.rb` (`test/integration/merchant_reassignments_test.rb`): `redirects with the number moved`; `redirects with an alert when a move fails`; `redirects to login when signed out`.
- `app/views/accounts/show.html.erb` (`test/integration/accounts_show_test.rb`): `show offers to mark an external account as a shared provider`; `show offers the move only for a provider`.
- `app/tools/assistant/*` (`test/integration/assistant_test.rb`): `the assistant unmarks a provider`; `the assistant is told when an account does not exist`; `the assistant is refused when marking a family account`; `the assistant is told when the account is no provider`; `the assistant is told when a move fails`; `both new tools say they change things`.

Test setup: fixtures `adyen` and `aon` accounts and three payments on `adyen` (see Files that change); the existing `kruidvat` account and its `Kruidvat` alias. The `kruidvat` fixture has no default category; tests that check the category rule give it one inline (`household`), so the existing fixture stays unchanged. Tests mark `adyen` with `update!(payment_provider: true)` or through the web or tool under test. Mollie and Buckaroo cases create their provider account inline in the test. Splits are created inline with `transaction_splits.create!`. A forced failure stubs nothing external: make one fixture transaction invalid for the test (for example an explicit split larger than its amount, written with `update_column`), so its `save!` raises. Import tests call `Importing::ING::ImportJob.perform_now` with an 11-column ING row. Nothing external is faked.

---
Domain skills applied: rails-architecture, object-oriented-design, rails-testing, rails-ui, ruby-style.

## Critique

### Round 1 (codex exec -p terra)

- Equality with the provider's default category cannot tell an automatic category from a hand-picked one that happens to match → dismissed: intent.md defines the rule this way ("whose category is still the provider's default category gets the merchant's default category"); provenance tracking would change agreed behaviour and add a column the intent did not approve.
- Stripping any " via "/" by " tail is too broad; strip only a tail naming the marked provider → dismissed: the intent asks to drop a trailing "via …"/"by …" suffix, and provider account names do not reliably match the suffix text (Buckaroo's account is "STICHTING DERDENGELDEN BUCKAROO"); the risk is recorded and limited to marked providers.
- Provider-alias handling is inconsistent between equality and substring matching → fixed (Design decisions now state one alias rule: the longest alias match wins, a provider alias match keeps the payment on the provider; two unit tests added for overlapping aliases)
- Case-insensitive name lookup is not deterministic; `absorb_transactions_for` does not order by id → fixed (plan now requires ordering by id before taking the first match, plus a unit test for duplicate names)
- The move is not idempotent by construction if it saves or counts staying transactions → fixed (design decision states the move skips and does not save or count a staying transaction; unit test for an unsaved staying transaction)
- The rollback proof does not cover a merchant account created before a later failure → fixed (rollback unit test now forces a later failure after a new merchant and asserts nothing remains)
- No user-facing handling of `ActiveRecord::RecordInvalid` in the controller and the tool → fixed (both rescue it and answer with an alert or `problem`; integration tests added)
- Only the provider-as-debitor direction is tested → fixed (added `refund_through_adyen` fixture, a `Bij` import test, and type preservation in the `move_counterparty` unit test)
- Import rows are processed sequentially with `perform_now`, so the concurrency risk was misstated → fixed (risk rewritten to concurrent uploads, verified in `Transactions::ImportsController#create`, and explicitly accepted)
