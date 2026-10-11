# Review: shared-payment-provider-accounts

## Round 1 — 2026-10-11 06:33 UTC — 817d3c4

Checks at review time: `bin/rails test` 948 runs, 0 failures, 0 skips; `rubocop`, herb-lint, Brakeman clean; `i18n-tasks normalize` changes nothing; no translations missing. No uncommitted changes. No existing test was weakened, skipped or deleted.

- [x] Nit: No test pins the most common move outcome: a transaction on the provider's default category moved to a merchant without a default category (every merchant the move creates, and the `kruidvat` fixture) becomes uncategorised. This matches the intent's rule, but no assertion covers it, and the confirm text does not warn that categories can be cleared. — `app/models/concerns/accountable.rb:38` → fixed (Warn that moving can clear a category, and pin that outcome)
- [x] Nit: A failed move reports only the validation message ("Validation failed: Amount …"), not which transaction failed. The move is all-or-nothing across hundreds of rows, so the user cannot find the one transaction that blocks it. Include the transaction id or date and amount in the alert and the tool's `problem`. — `app/controllers/accounts/merchant_reassignments_controller.rb:12`, `app/tools/assistant/move_transactions_to_merchants.rb:22` → fixed (Name the transaction that blocks a move)
- [x] Nit: `activerecord.attributes.account.payment_provider` has no translation, so the refusal alert reads "Payment provider moet een externe rekening zijn" (nl) and "Payment provider deve essere un conto esterno" (it), with an English attribute name. — `config/locales/nl.yml:56` → fixed (Name the payment provider attribute in every language)
- [x] Nit: `own_name?` plucks the provider's alias patterns again for every payment, and `split?` queries splits for each one. Each moved row costs several extra queries. That is acceptable at a few hundred rows, but the provider's names can be read once per move. — `app/models/concerns/payment_provider.rb:68` → fixed (Read a provider's names once per move, and query splits only when the category matters)
- [x] Nit: `change(provider, success_key)` takes a boolean flag that switches behaviour (control coupling). Two intention-revealing calls, or passing the value straight to one `update`-and-redirect helper with the key derived from the action, reads more clearly. — `app/controllers/accounts/payment_providers_controller.rb:27` → fixed (Replace the boolean switch in the payment provider controller)

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Shared Adyen, "Naam: Kruidvat" books on Kruidvat | `test/jobs/importing/ing/import_job_test.rb` "a payment through a shared provider books on the merchant's existing account" |
| "Naam: Kirovanni/Foodticket" creates and books on a new account | `import_job_test.rb` "a payment through a shared provider to an unknown merchant creates that merchant" |
| Mollie "via" suffix dropped | `import_job_test.rb` "a via suffix is dropped from the merchant name" |
| Buckaroo "by" suffix dropped | `import_job_test.rb` "a by suffix is dropped from the merchant name" |
| "Naam: Adyen" stays on Adyen | `import_job_test.rb` "a payment naming the provider itself stays on the provider" |
| AON (not shared) still books on AON | `import_job_test.rb` "a payment to an account that is not a shared provider books on that account" |
| Newly shared: stays until the move, then moves | `test/integration/merchant_reassignments_test.rb` "marking a provider leaves its transactions until they are moved" |
| Provider default category becomes merchant default | `merchant_reassignments_test.rb` "a moved transaction with the provider's default category gets the merchant's default" |
| Hand-picked category and splits kept | `merchant_reassignments_test.rb` "a moved transaction keeps a category chosen by hand", "a moved split transaction keeps its splits" |
| Second move moves nothing | `merchant_reassignments_test.rb` "moving a second time moves nothing" |
| Unmark: new import books on Adyen, moved ones stay | `test/integration/payment_providers_test.rb` "unmarking a provider books new imports on it and leaves moved transactions" |
| Assistant marks and moves with the same results | `test/integration/assistant_test.rb` "the assistant marks a shared provider and moves its transactions to their merchants" |

Every test named in `plan.md` `## Proof` exists in the diff.

## Round 2 — 2026-10-11 06:30 UTC — 817d3c4 (codex)

`codex review --base origin/main`: no findings. Its focused run passed 124 tests, 345 assertions, no failures or errors.

## Round 3 — 2026-10-11 06:39 UTC — 2356054

Checks at review time: `bin/rails test` 950 runs, 0 failures, 0 errors, 0 skips; `rubocop` (309 files), herb-lint, Brakeman and bundler-audit clean; `i18n-tasks normalize` changes nothing; no translations missing. No uncommitted changes. No existing test was weakened, skipped or deleted.

Round-1 fixes verified:

- Category cleared at a merchant without a default: the confirm text in en/nl/it now warns about it, and `merchant_reassignments_test.rb` "a moved transaction with the provider's default category loses it at a merchant without a default" pins it. Holds.
- Blocking transaction named: `PaymentProvider::MoveFailed` puts "<model> #<id>: <reason>" in its message. The controller alert and the tool's `problem` both carry it, and both tests assert `#<id>`. Holds.
- Attribute name translated: `activerecord.attributes.account.payment_provider` exists in en, nl and it. `payment_provider_test.rb` asserts the Dutch full message. Holds.
- Names read once per move: `own_name?` maps the loaded `account_aliases` association on the provider instance, so a move loads the aliases once. `follows_default_category_of?` checks the category first and calls `split?` only when the category matches. Holds.
- Boolean switch removed: `update_and_redirect(attributes)` takes the value, and the notice key comes from `action_name`. Holds.

- [x] Nit: The rollback test only proves that a merchant created mid-move is rolled back if `refund_through_adyen` (booked 13 Aug) is processed before `kruidvat_through_adyen` (booked 10 Aug). That order comes only from `Transaction`'s `default_scope` (`booked_at: :desc`), and the test does not check that the move created the new merchant before it failed. If the order changes, the failing transaction runs first, "Brand New Shop" is never created, and `assert_no_difference "Account.count"` still passes. The test also does not check that the failing transaction's explicit split is unchanged, which the plan asks for. — `test/models/concerns/payment_provider_test.rb:147` → fixed (Prove the rollback test's order and the failing transaction's splits)

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Shared Adyen, "Naam: Kruidvat" books on Kruidvat | `test/jobs/importing/ing/import_job_test.rb` "a payment through a shared provider books on the merchant's existing account" |
| "Naam: Kirovanni/Foodticket" creates and books on a new account | `import_job_test.rb` "a payment through a shared provider to an unknown merchant creates that merchant" |
| Mollie "via" suffix dropped | `import_job_test.rb` "a via suffix is dropped from the merchant name" |
| Buckaroo "by" suffix dropped | `import_job_test.rb` "a by suffix is dropped from the merchant name" |
| "Naam: Adyen" stays on Adyen | `import_job_test.rb` "a payment naming the provider itself stays on the provider" |
| AON (not shared) still books on AON | `import_job_test.rb` "a payment to an account that is not a shared provider books on that account" |
| Newly shared: stays until the move, then moves | `test/integration/merchant_reassignments_test.rb` "marking a provider leaves its transactions until they are moved" |
| Provider default category becomes merchant default | `merchant_reassignments_test.rb` "a moved transaction with the provider's default category gets the merchant's default" |
| Hand-picked category and splits kept | `merchant_reassignments_test.rb` "a moved transaction keeps a category chosen by hand", "a moved split transaction keeps its splits" |
| Second move moves nothing | `merchant_reassignments_test.rb` "moving a second time moves nothing" |
| Unmark: new import books on Adyen, moved ones stay | `test/integration/payment_providers_test.rb` "unmarking a provider books new imports on it and leaves moved transactions" |
| Assistant marks and moves with the same results | `test/integration/assistant_test.rb` "the assistant marks a shared provider and moves its transactions to their merchants" |

Every test named in `plan.md` `## Proof` exists in the diff, including all per-file unit tests.

## Round 4 — 2026-10-11 06:40 UTC — 2356054 (codex)

- [x] Important: Cache provider aliases during bulk moves: `own_name?` reloads `account_aliases` for every transaction, and `move_counterparty` checks `split?` for every transaction, adding database round trips per row (codex P2). — `app/models/concerns/payment_provider.rb:81` → dismissed: does not hold at 2356054. A query count over a move of the four `adyen` fixtures shows one alias load for the provider (`account_aliases.map` loads the association once, from "Read a provider's names once per move, and query splits only when the category matters"), and `split?` runs only when the category equals the provider's default. The split queries left come from `Splittable`'s save validation and `after_save` remainder sync, which every save needs.

## Round 5 — 2026-10-11 06:44 UTC — 59570d9

Checks at review time: `bin/rails test` 951 runs, 2529 assertions, 0 failures, 0 errors, 0 skips; `rubocop` (309 files), herb-lint, Brakeman and bundler-audit clean; `i18n-tasks normalize` changes nothing; no translations missing. No uncommitted changes. No existing test was weakened, skipped or deleted (the diff removes no line under `test/`).

Earlier closures verified:

- Round 3 rollback test: `break_a_move_after_a_new_merchant` now sets `booked_at` so the new-merchant payment sorts first, and asserts that order on the same `by_account` scope the move uses. The test asserts "Brand New Shop" does not exist after the rollback. A separate test asserts the failing transaction keeps its debitor and its explicit split `[10, bakery]`. Holds.
- Round 4 dismissal: `app/` is unchanged since 2356054. A query probe over a move of the four `adyen` fixtures at 59570d9 shows 23 queries, one `account_aliases` load for the provider, and 8 split queries for 3 saved moves (validation, remainder sync, and `split?` only where the category matches). The dismissal reason holds.

- [x] Nit: The `move_transactions_to_merchants` tool description says categories chosen by hand and splits are kept, but does not say that a payment on the provider's default category takes the merchant's default, or loses its category when the merchant has none. The web confirm text warns about this since round 1; the assistant gets no such warning before a destructive call. — `app/tools/assistant/move_transactions_to_merchants.rb:4` → fixed (Tell the assistant that a default category follows the merchant)
- [x] Nit: The move notice has no plural forms, so one moved payment reads "1 transactions moved to their merchants." (en), "1 transacties verplaatst" (nl), "1 transazioni spostate" (it), and the tool answers "Moved 1 transactions". The existing bulk-update notice has the same flaw, so this follows precedent. — `config/locales/en.yml:575`, `app/tools/assistant/move_transactions_to_merchants.rb:21` → fixed (Announce a single moved transaction in the singular)

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Shared Adyen, "Naam: Kruidvat" books on Kruidvat | `test/jobs/importing/ing/import_job_test.rb` "a payment through a shared provider books on the merchant's existing account" |
| "Naam: Kirovanni/Foodticket" creates and books on a new account | `import_job_test.rb` "a payment through a shared provider to an unknown merchant creates that merchant" |
| Mollie "via" suffix dropped | `import_job_test.rb` "a via suffix is dropped from the merchant name" |
| Buckaroo "by" suffix dropped | `import_job_test.rb` "a by suffix is dropped from the merchant name" |
| "Naam: Adyen" stays on Adyen | `import_job_test.rb` "a payment naming the provider itself stays on the provider" |
| AON (not shared) still books on AON | `import_job_test.rb` "a payment to an account that is not a shared provider books on that account" |
| Newly shared: stays until the move, then moves | `test/integration/merchant_reassignments_test.rb` "marking a provider leaves its transactions until they are moved" |
| Provider default category becomes merchant default | `merchant_reassignments_test.rb` "a moved transaction with the provider's default category gets the merchant's default" |
| Hand-picked category and splits kept | `merchant_reassignments_test.rb` "a moved transaction keeps a category chosen by hand", "a moved split transaction keeps its splits" |
| Second move moves nothing | `merchant_reassignments_test.rb` "moving a second time moves nothing" |
| Unmark: new import books on Adyen, moved ones stay | `test/integration/payment_providers_test.rb` "unmarking a provider books new imports on it and leaves moved transactions" |
| Assistant marks and moves with the same results | `test/integration/assistant_test.rb` "the assistant marks a shared provider and moves its transactions to their merchants" |

Every test named in `plan.md` `## Proof` exists in the diff, including all per-file unit tests (checked by name with `grep`).

## Round 6 — 2026-10-11 06:44 UTC — 59570d9 (codex)

`codex review --base origin/main`: no findings. Its focused run passed 146 tests, 419 assertions, no failures or errors.

## Round 7 — 2026-10-11 06:49 UTC — 169cc2e

Checks at review time: `bin/rails test` 954 runs, 2533 assertions, 0 failures, 0 errors, 0 skips; `rubocop` (309 files), herb-lint, Brakeman and bundler-audit clean; `i18n-tasks normalize` changes nothing; no translations missing. No uncommitted changes. No existing test was weakened, skipped or deleted (the diff removes no line under `test/`).

Round-5 fixes verified:

- Tool description: `move_transactions_to_merchants` now says a transaction on the provider's default category gets the merchant's default, or none. `assistant_test.rb` "the move tool warns that a default category follows the merchant" pins it. Holds.
- Singular notice: `merchant_reassignments.create.success` has `one`/`other` in en, nl and it; the controller passes `count:`. The tool answers "Moved 1 transaction from Adyen to its merchant." for one. `merchant_reassignments_test.rb` "a single moved transaction is announced in the singular" and `assistant_test.rb` "the assistant hears about a single moved transaction in the singular" pin both. Holds.

- [x] Nit: The new helper `self.moved` is a public class method on the tool. Every other tool helper (`Tool.answer`, `Tool.problem`, all of `BudgetStatus`'s helpers) is marked `private_class_method`. — `app/tools/assistant/move_transactions_to_merchants.rb:27` → fixed (Keep the move tool's message helper private, like other tool helpers)

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Shared Adyen, "Naam: Kruidvat" books on Kruidvat | `test/jobs/importing/ing/import_job_test.rb` "a payment through a shared provider books on the merchant's existing account" |
| "Naam: Kirovanni/Foodticket" creates and books on a new account | `import_job_test.rb` "a payment through a shared provider to an unknown merchant creates that merchant" |
| Mollie "via" suffix dropped | `import_job_test.rb` "a via suffix is dropped from the merchant name" |
| Buckaroo "by" suffix dropped | `import_job_test.rb` "a by suffix is dropped from the merchant name" |
| "Naam: Adyen" stays on Adyen | `import_job_test.rb` "a payment naming the provider itself stays on the provider" |
| AON (not shared) still books on AON | `import_job_test.rb` "a payment to an account that is not a shared provider books on that account" |
| Newly shared: stays until the move, then moves | `test/integration/merchant_reassignments_test.rb` "marking a provider leaves its transactions until they are moved" |
| Provider default category becomes merchant default | `merchant_reassignments_test.rb` "a moved transaction with the provider's default category gets the merchant's default" |
| Hand-picked category and splits kept | `merchant_reassignments_test.rb` "a moved transaction keeps a category chosen by hand", "a moved split transaction keeps its splits" |
| Second move moves nothing | `merchant_reassignments_test.rb` "moving a second time moves nothing" |
| Unmark: new import books on Adyen, moved ones stay | `test/integration/payment_providers_test.rb` "unmarking a provider books new imports on it and leaves moved transactions" |
| Assistant marks and moves with the same results | `test/integration/assistant_test.rb` "the assistant marks a shared provider and moves its transactions to their merchants" |

Every test named in `plan.md` `## Proof` exists in the diff, including all per-file unit tests (checked by name with `grep`).

## Round 8 — 2026-10-11 06:49 UTC — 169cc2e (codex)

`codex review --base origin/main`: no findings. "The payment-provider import and reassignment paths preserve transaction types, categories, splits, and rollback behavior."
