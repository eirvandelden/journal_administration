# Review: shared-payment-provider-accounts

## Round 1 — 2026-10-11 06:33 UTC — 817d3c4

Checks at review time: `bin/rails test` 948 runs, 0 failures, 0 skips; `rubocop`, herb-lint, Brakeman clean; `i18n-tasks normalize` changes nothing; no translations missing. No uncommitted changes. No existing test was weakened, skipped or deleted.

- [x] Nit: No test pins the most common move outcome: a transaction on the provider's default category moved to a merchant without a default category (every merchant the move creates, and the `kruidvat` fixture) becomes uncategorised. This matches the intent's rule, but no assertion covers it, and the confirm text does not warn that categories can be cleared. — `app/models/concerns/accountable.rb:38` → fixed (Warn that moving can clear a category, and pin that outcome)
- [x] Nit: A failed move reports only the validation message ("Validation failed: Amount …"), not which transaction failed. The move is all-or-nothing across hundreds of rows, so the user cannot find the one transaction that blocks it. Include the transaction id or date and amount in the alert and the tool's `problem`. — `app/controllers/accounts/merchant_reassignments_controller.rb:12`, `app/tools/assistant/move_transactions_to_merchants.rb:22` → fixed (Name the transaction that blocks a move)
- [x] Nit: `activerecord.attributes.account.payment_provider` has no translation, so the refusal alert reads "Payment provider moet een externe rekening zijn" (nl) and "Payment provider deve essere un conto esterno" (it), with an English attribute name. — `config/locales/nl.yml:56` → fixed (Name the payment provider attribute in every language)
- [ ] Nit: `own_name?` plucks the provider's alias patterns again for every payment, and `split?` queries splits for each one. Each moved row costs several extra queries. That is acceptable at a few hundred rows, but the provider's names can be read once per move. — `app/models/concerns/payment_provider.rb:68` →
- [ ] Nit: `change(provider, success_key)` takes a boolean flag that switches behaviour (control coupling). Two intention-revealing calls, or passing the value straight to one `update`-and-redirect helper with the key derived from the action, reads more clearly. — `app/controllers/accounts/payment_providers_controller.rb:27` →

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
