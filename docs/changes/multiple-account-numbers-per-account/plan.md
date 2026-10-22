# Plan: One external account can hold several account numbers

From `intent.md` (2026-10-16). Status: accepted.

## Context

Albert Heijn pays and is paid through three account numbers, but `accounts.account_number` holds one number per account. Each import with a new number creates another external `Account`, so one shop shows up as three. This change moves numbers into their own table, matches imports against every number, and adds a merge action that folds duplicates into one account.

## Design decisions

- **Numbers live in a new `account_numbers` table** (`account_id`, `number`, timestamps), with a unique index on `number`. One source of truth; uniqueness holds in the database, not only in a validation. Rejected: keeping `accounts.account_number` as a "primary" number plus a table for extras — uniqueness across two tables cannot be enforced by an index.
- **`accounts.account_number` stays in the database but is ignored** (`self.ignored_columns += [ "account_number" ]` on `Account`). Playbook rule 9 forbids dropping it without explicit approval. Dropping it is a follow-up change.
- **Existing numbers are copied by a data migration** in `db/data/`, in raw SQL (the column is ignored by Active Record). Deploys run it through `db:migrate:with_data` (`lib/tasks/data_migrate.rake`). The copy normalizes as the model does: trimmed, spaces removed, upper case. Blank numbers are skipped.
- **`AccountNumber` normalizes** `number` (`normalizes :number, with: ->(number) { number.gsub(/\s+/, "").upcase }`), so `"nl46 ingb …"` and `"NL46INGB…"` are one number, also in finder queries.
- **The refusal message names the owner**: a custom validation adds `:number, :taken_by, account: <other account's to_s>`, so the user reads "Account number NL46INGB0702493368 already belongs to Albert Heijn B.V.". The unique index is the backstop.
- **Numbers are edited in the account form** (new and edit pages), as nested fields: `accepts_nested_attributes_for :account_numbers, allow_destroy: true, reject_if: <blank new number>`. Each existing number shows as a text field with a "Remove" checkbox (`_destroy`); one empty field adds a new number. No JavaScript: adding two numbers means saving twice. The show page lists the numbers read-only. An `Account` validation refuses the same number twice within one save, which the database check alone would only catch as an exception.
- **Numbers are not restricted to external accounts.** Household accounts already hold numbers (the ING import finds "our" account by number). Nothing in the UI stops a household account from holding two; that is harmless and not promoted.
- **Merge lives on the target account** in a new concern `app/models/concerns/mergeable.rb`, included in `Account` like `PaymentProvider` and `Resolvable`. No service object.
  - `Account#merge(duplicates)` returns `true`, or `false` with errors on `:base`. In one database transaction it moves, by `update_all` (as `absorb_transactions_for` does today): `transactions.debitor_account_id`, `transactions.creditor_account_id`, `receipts.shop_id`, `account_aliases.account_id`, `account_numbers.account_id`. Then it sets `category` when the target has none, then destroys the duplicates.
  - Refusals: no duplicates picked; the target is a household account; a duplicate is a household account; a duplicate is the target itself; a duplicate is a payment provider while the target is not (Etienne, plan stage: a provider's IBAN on a shop would stop imports through it being split by merchant).
  - Category: the target keeps its own. When it has none, it takes the category of the first duplicate by `id` that has one.
  - Transactions keep their own category and splits. The `Debit`/`Credit`/`Transfer` type does not change, because only external accounts merge into external accounts.
  - `Account.transactions_count_by_account(ids)` (debit and credit side, one grouped query each) and `Account.receipts_count_by_account(ids)` return `{id => count}` hashes that feed the preview; the receipts total is the sum of the grouped values. `Account` gains `has_many :receipts, foreign_key: :shop_id, inverse_of: :shop`.
- **Merge UI is a nested singular resource**: `resource :merge, only: %i[new create]` under `accounts`, `Accounts::MergesController`. The account page (external accounts only) links to "Merge duplicates…".
  - `new` without `duplicate_ids`: a search field (GET, `query`) over `Account.external.where.not(id:).search(query)` and a checkbox list of matches with their numbers. Nothing is suggested before the user types (automatic detection is out of scope). "Review merge" submits the ticked ids back to `new` by GET.
  - `new` with `duplicate_ids`: lists each duplicate with its transaction and receipt counts, the totals, and a "Merge" `button_to` to `create` carrying the ids and a native `data-turbo-confirm` that states the counts, e.g. "Merge 3 accounts into Albert Heijn B.V.? 412 transactions and 37 receipts move. This cannot be undone." The native confirm follows the standing UI decision; no custom dialog.
  - `create` redirects to the account with a notice that states the counts, or back to `new` with the refusal as alert.
  - Searching more than once to collect duplicates is not supported: a duplicate from another search is merged in a second run.
- **Search over numbers**: `Searchable` gains association columns, `searchable_on :name, account_numbers: :number`, compiled as `accounts.id IN (SELECT account_id FROM account_numbers WHERE number LIKE ?)`. A subquery, not a join, so no `DISTINCT` and `FindAccounts#held_back`'s `limit(nil).count` keeps working.
- **Import matching**: `Account.find_or_create_by_number(number)` in `Resolvable` returns the account that owns the number, or creates an account with that number. Creation is one transaction (`create!(account_numbers: [ AccountNumber.new(number:) ])`), and an `ActiveRecord::RecordNotUnique` from a parallel import falls back to the account that won. `resolve_for_import` and `Importing::ING::ImportJob` call it instead of `find_or_create_by(account_number:)`. `resolve_from_description` plucks household numbers from `account_numbers`.
- **Display**: `Account#numbers` returns the numbers as strings. `Account#to_s` falls back to the first number. Views that read `account_number` switch to `numbers` or `to_s`.

## Integration points

- Bank import: `Importing::ING::ImportJob`, `Resolvable`, `PaymentProvider#counterparty_for` (unchanged, receives the resolved account).
- MCP assistant: `Assistant::FindAccounts` uses `Account.search` and `Account#to_s`; both keep working. No tool reads `account_number`.
- Global search: `Search#compute_results` and `app/views/searches/_result_account.html.erb`.
- JSON: `app/views/accounts/_account.json.jbuilder` exposes `account_numbers` (array) instead of `account_number`.
- Deploy: the new schema and data migrations run through `db:migrate:with_data` on `db:prepare`. No deploy file changes.

## Files that change

- `db/migrate/<ts>_create_account_numbers.rb` — new table, `references :account, null: false, foreign_key: true`, `string :number, null: false`, unique index on `number`.
- `db/data/<ts>_copy_account_numbers_from_accounts.rb` — SQL copy of non-blank, normalized `accounts.account_number`; `down` raises `IrreversibleMigration`.
- `db/schema.rb`, `db/data_schema.rb` — regenerated by the migrations (only the new table and versions; do not commit a re-ordered dump).
- `app/models/account_number.rb` — new model: `belongs_to :account`, normalization, presence, `taken_by` validation.
- `app/models/account.rb` — `ignored_columns`, `has_many :account_numbers, dependent: :destroy`, `accepts_nested_attributes_for`, `has_many :receipts`, `include Mergeable`, `searchable_on :name, account_numbers: :number`, drop the `account_number` uniqueness validation, `numbers`, `to_s` fallback, distinct-numbers validation.
- `app/models/concerns/mergeable.rb` — new: `merge`, `transactions_count_by_account`, `receipts_count_by_account`, refusal checks.
- `app/models/concerns/resolvable.rb` — `find_or_create_by_number`, number lookups through `account_numbers`.
- `app/models/concerns/searchable.rb` — association columns as subqueries.
- `app/jobs/importing/ing/import_job.rb` — `find_or_create_by_number` for our account.
- `app/controllers/accounts_controller.rb` — strong params `account_numbers_attributes: [ :id, :number, :_destroy ]` instead of `:account_number`; build one blank number in `new`/`edit`; `includes(:account_numbers)` on index.
- `app/controllers/accounts/merges_controller.rb` — new: `new`, `create`, strong params for `duplicate_ids` and `query`.
- `config/routes.rb` — `resource :merge, only: %i[new create]` in the accounts module scope.
- `app/views/accounts/_form.html.erb` — nested number fields with Remove checkboxes and one blank field.
- `app/views/accounts/show.html.erb` — numbers list; "Merge duplicates…" link for external accounts.
- `app/views/accounts/index.html.erb`, `app/views/searches/_result_account.html.erb`, `app/views/transactions/_table.html.erb`, `app/views/shared/_recent_transactions.html.erb`, `app/views/accounts/_account.json.jbuilder` — `numbers` / `to_s` instead of `account_number`.
- `app/views/accounts/merges/new.html.erb` — search, pick, preview, confirm.
- `config/locales/{en,nl,it}.yml` — new strings (numbers label, remove, taken_by, merge page, refusals, confirm, notice); `bundle exec i18n-tasks normalize`.
- `test/fixtures/account_numbers.yml` — one row per fixture account that had a number; `test/fixtures/accounts.yml` loses `account_number:`.
- Tests that set or read `account_number` move to `account_numbers` (`account_test`, `searchable_test`, `resolvable_test`, `importable_test`, `bulk_updatable_test`, `import_job_test`, `payment_providers_test`, `accounts_index_test`, `pagination_navigation_test`).

## Order of work

1. Write the acceptance test `test/integration/account_merges_test.rb` "merging duplicates moves transactions, receipts and numbers and removes the duplicates". Run it, watch it fail (no route).
2. Migration and `AccountNumber` model with its unit tests; `account_numbers.yml` fixtures; `Account` associations and `ignored_columns`; move every fixture and test that uses `account_number`. Full suite green before going on.
3. Data migration and its test in `test/data/`.
4. `Searchable` association columns; search tests.
5. `Resolvable#find_or_create_by_number` and the ING import job; import tests for a known second number.
6. Account form and show page with nested numbers; `AccountsController` strong params; integration tests for adding, removing and the refused duplicate.
7. `Mergeable` with unit tests for each refusal, the category rule and the counts.
8. `Accounts::MergesController`, route, `merges/new` view, show-page link; make the step 1 acceptance test pass, then the other merge integration tests.
9. Remaining views (`index`, search result, transaction tables, JSON); locales in three languages; `i18n-tasks normalize`.
10. Rubocop, herb-lint, Brakeman, bundler-audit, full test suite. Run the worktree locally (copy the dev database, `DISABLE_SSL=1`, port 3001) and merge the three numbered Albert Heijn accounts in a copy of the dev data to verify by hand.

## Risks

- **Existing duplicate numbers in production** would make the copy fail on the unique index. The current uniqueness validation makes this unlikely, and the dev database has 323 numbers, all distinct after normalization. If it happens, the migration fails inside its transaction and nothing changes; fix the data and redeploy.
- **The ignored column goes stale.** Nothing reads or writes it after this change. Dropping it needs explicit approval and is a separate change.
- **`update_all` skips callbacks and `updated_at`** on moved transactions, receipts, aliases and numbers. This matches `absorb_transactions_for` today. Transaction types stay correct because only external accounts merge.
- **Merge is final.** Undo is out of scope; the confirm states the counts.
- **A parallel import race** on a new number now fails on the taken-number validation (`RecordInvalid`, since SQLite takes the write lock first) or the unique index (`RecordNotUnique`) instead of silently creating two accounts; `find_or_create_by_number` rescues both and falls back to the existing account.
- **Rejected**: a Stimulus controller that rewrites the confirm text as boxes are ticked (adds JavaScript for one sentence; the GET preview does it on the server); a search-and-add widget for numbers on the show page (Etienne prefers the edit page).

## Out of scope

- Dropping `accounts.account_number`.
- Undoing a merge, or keeping merged accounts as inactive.
- Merging household accounts.
- Suggesting or detecting duplicates automatically.
- Collecting duplicates across several searches in one merge.
- Changing `AccountAlias` matching or the "absorb transactions" action.

## Proof

- Albert Heijn has three numbers on one account, and a transaction from any of the three shows under it → `test/integration/account_merges_test.rb` `merging duplicates moves transactions, receipts and numbers and removes the duplicates`; `test/jobs/importing/ing/import_job_test.rb` `a transaction from any number of an account books on that account`
- Importing a transaction from a known second number does not create a new account → `test/jobs/importing/ing/import_job_test.rb` `importing from a known second number creates no account`
- Saving a number that already belongs to another account is refused with a clear message → `test/integration/account_numbers_test.rb` `saving a number of another account is refused and names that account`
- Merging duplicates from an account page moves all their transactions, receipts and numbers to that account, and its totals add up → `test/integration/account_merges_test.rb` `merging duplicates moves transactions, receipts and numbers and removes the duplicates`
- The target account keeps its own name. It keeps its own default category, or takes the first one from the duplicates when it has none → `test/models/concerns/mergeable_test.rb` `merge keeps the target's name and category`, `merge gives a target without category the first duplicate's category`
- After a merge the emptied duplicate account no longer exists → `test/integration/account_merges_test.rb` `merging duplicates moves transactions, receipts and numbers and removes the duplicates`
- Merging a household-owned account with an external one is refused → `test/integration/account_merges_test.rb` `merging a household account is refused`; `test/models/concerns/mergeable_test.rb` `merge refuses a household duplicate`, `merge refuses a household target`
- Merge asks for confirmation and states how many transactions and receipts move → `test/integration/account_merges_test.rb` `the review step confirms with the transaction and receipt counts`
- Searching any one of the numbers finds the merged account → `test/models/search_test.rb` `results include an account matching any of its numbers`

Per changed file, the unit tests expected, named as behaviour:
- `app/models/account_number.rb`: `AccountNumber normalizes spaces and case`, `refuses a blank number`, `refuses a number of another account and names that account`
- `app/models/account.rb`: `Account#numbers lists every number`, `to_s falls back to the first number`, `refuses the same number twice in one save`, `destroying an account removes its numbers`, `nested attributes add a number`, `nested attributes remove a number`, `nested attributes ignore a blank new number`
- `app/models/concerns/mergeable.rb`: `merge moves transactions on both sides`, `merge moves receipts`, `merge moves aliases`, `merge moves numbers`, `merge destroys the duplicates`, `merge keeps the target's name and category`, `merge gives a target without category the first duplicate's category`, `merge refuses an empty selection`, `merge refuses the target itself`, `merge refuses a household duplicate`, `merge refuses a household target`, `merge refuses a payment provider into a non-provider`, `merge changes nothing when refused`, `transactions_count_by_account counts the transactions on either side per account`, `transactions_count_by_account counts a transaction between two accounts once for each`, `transactions_count_by_account is empty for no accounts`, `receipts_count_by_account counts the receipts bought at each account`
- `app/models/concerns/resolvable.rb`: `find_or_create_by_number finds the owner of any number`, `creates an account with the number when unknown`, `falls back to the existing account when a parallel import won`, `resolve_from_description matches any household number`
- `app/models/concerns/searchable.rb`: `search matches an association column`, `search counts each record once when several numbers match`
- `db/data/<ts>_copy_account_numbers_from_accounts.rb`: `copies every non-blank number, normalized`, `skips blank numbers`
- `app/controllers/accounts/merges_controller.rb`: covered by the integration tests above, plus `merge page lists external matches for the query and not the target` and `unauthenticated users are sent to sign in`

Test setup: fixtures. New `test/fixtures/account_numbers.yml` carries the numbers now on `accounts.yml`, plus two extra numbers for an Albert Heijn duplicate pair. Receipts fixtures already point at shops; add one receipt on a duplicate. Integration tests sign in with `sign_in_as(users(:member))`. Data-migration tests write `accounts.account_number` with SQL, since the column is ignored.

---
Domain skills applied: rails-architecture, object-oriented-design, rails-ui, rails-testing, ruby-style.
