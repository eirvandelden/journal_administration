# Review: cents-instead-of-decimals

## Round 1 — 2026-10-17T05:56Z — 08c9f01 (codex)

No findings. Codex reviewed the diff against origin/main and ran the suite: 1107 tests, 0 failures.

## Round 2 — 2026-10-17T06:02Z — 08c9f01 (claude)

Suite green (1107 runs, 0 failures), RuboCop and Brakeman clean. The herb linter did not run: this worktree has no `node_modules`. The real-data snapshots in `tmp/` match: `before.txt` = `after.txt` and `raw_before.txt` = `raw_after_rollback.txt`.

Compliance, acceptance criteria:

- 1,5 stored as 150 and shown as 1,50 → `test/migrations/convert_money_to_cents_test.rb` "up stores a transaction of 1,5 as 150 cents", `test/integration/transaction_amounts_test.rb` "a transaction of 150 cents shows as 1,50"
- Typing 1,50 stores 150 and shows 1,50 → `transaction_amounts_test.rb` "typing 1,50 stores 150 cents and the form shows 1,50 again"
- 1,5 and 1.50 give the same result → `transaction_amounts_test.rb` "typing 1,5 or 1.50 stores 150 cents"
- 12,34 split into 10,00 and 2,34 → `test/integration/transaction_splits_test.rb` "splitting 12,34 into 10,00 and 2,34 leaves nothing unsplit"
- Receipt lines still add up → migration test "receipt lines that add up to the total still do after up"
- Budget and dashboard figures unchanged → existing dashboard and budget integration tests on cent fixtures, plus the real-data comparison (identical)
- Budget status reports 12.50 for 1250 → `test/tools/assistant/budget_status_test.rb` "reports a plan of 1250 cents as 12.50"
- Real data unchanged after the migration → `tmp/before.txt` and `tmp/after.txt` identical
- Rollback restores decimals → migration test "down restores the original decimal values", plus `tmp/raw_before.txt` and `tmp/raw_after_rollback.txt` identical

No existing test was removed or skipped; the removed assertions are euro literals rewritten as cents.

- [ ] Important: plan Proof names `find_uncategorized_transactions.rb` "reports amounts in euros as before", but no such test exists and no test asserts the amount this tool prints, so a regression to raw cents ("1250") would pass the suite — `app/tools/assistant/find_uncategorized_transactions.rb:30` → fixed (Test the euro amounts that two assistant tools print)
- [ ] Important: plan Proof names `charge_to_appropriation.rb` "reports amounts in euros as before", but no test asserts the amount in "Charged … to …" or in the list of split parts, so neither euro conversion is proven — `app/tools/assistant/charge_to_appropriation.rb:61` → fixed (Test the euro amounts that two assistant tools print)
- [ ] Important: plan Proof names `_transaction.json.jbuilder` "renders the amount in euros as before", but no test reads the JSON amount of a transaction; the intent requires the JSON views to keep the decimal format — `app/views/transactions/_transaction.json.jbuilder:4` → fixed (Test the amount in the transaction JSON partial)
- [ ] Nit: an unreadable amount on a model with `presence` and `comparison` shows three messages, two of them duplicates ("Amount is not an amount", "Amount can't be blank", "Amount can't be blank"); the split form prints all three. A number field still gets there when an en user types the ambiguous `1.500` — `app/models/concerns/monetary.rb:24` → fixed (Show one message for an unreadable amount)
- [ ] Nit: `printf('%.2f', amount / 100.0)` returns `'0.00'` for a NULL amount, where `CAST(NULL AS TEXT)` never matched; a search containing "0" or ".00" now also returns transactions without an amount — `app/models/transaction.rb:31` → fixed (Keep transactions without an amount out of the amount search)
- [ ] Nit: five Proof names have no test of that name (TransactionSplit "accepts an amount typed with a comma" and "refuses more than the balance in cents", ReceiptLine "paid amount follows from the bonus in cents", Dashboard "budget actuals are Integer cents", PackingSlip "reads lines and total as cents"). Updated existing tests and the split integration test cover the behaviour; rename them or update the plan so the Proof list can be traced — `docs/changes/cents-instead-of-decimals/plan.md:159` → fixed (Name five tests after the plan Proof list)

## Round 3 — 2026-10-17T06:15Z — 3ae5c6c (codex)

No findings. Codex reviewed the diff against origin/main and ran the suite: 1116 tests, 0 failures.

## Round 4 — 2026-10-17T06:27Z — 3ae5c6c (claude)

No findings. Suite green (1116 runs, 0 failures). RuboCop, the herb linter and Brakeman are clean. `i18n-tasks normalize` changes nothing.

The six Round 2 findings hold at this SHA:

- `find_uncategorized_transactions_test.rb` and `charge_to_appropriation_test.rb` assert the euro text the tools print, including both split parts.
- `transaction_json_test.rb` asserts the JSON amount `"12.5"`, the same BigDecimal string the decimal column gave.
- `Monetary` keeps the `validate` block, so `valid?` still returns false, and the `after_validation` callback leaves one message; `monetary_test.rb` proves it.
- The amount search skips a NULL amount; `transaction_test.rb` proves it for "0" and ".00".
- Every test named in the plan's Proof list now exists under that name; each renamed test asserts what its new name says.

No existing test was weakened, skipped or deleted in the fix commits.

Outside this change: `transactions/_transaction.json.jbuilder` reads `from_account_id` and `to_account_id`, which no longer exist, so the JSON index and show views fail on origin/main too. `transaction_json_test.rb` stubs them. Propose a separate branch for it.

## Round 5 — 2026-10-22T07:30Z — e95037f (claude)

The branch is rebased onto `origin/main` (0026a36), which brought in appropriation charges and the headless-Edge system tests. Suite green (1150 runs, 0 failures). RuboCop, the herb linter and Brakeman are clean. `i18n-tasks normalize` changes nothing.

Rebase check: main's new money code (`Appropriation#charged`, `#balance`, `charged_on`, the appropriation views and the `credit`/`debit` test helpers) reads Integer cents and renders through `cents_to_currency`. `e95037f` only rewrites euro literals in main's new tests as cents; no assertion was weakened, skipped or deleted. `db/schema.rb` differs from main's only in the ten money columns and the version. A sweep finds no `number_to_currency` outside `MoneyHelper` and no Float or BigDecimal money arithmetic left in `app/`.

Compliance: every acceptance criterion keeps the test Round 2 listed, and every test named in the plan's Proof list exists under that name.

- [ ] Nit: `euros_to_cents` assigns into the `permitted` parameters it receives, which the playbook forbids ("Never mutate a method's parameters"); return a copy instead, for example `permitted.merge(converted)` — `app/controllers/concerns/money_params.rb:15` → fixed (Return a copy from euros_to_cents instead of mutating its parameter)

## Round 6 — 2026-10-22T07:34Z — abdcdcd (claude)

No findings. Suite green (1150 runs, 0 failures). RuboCop, the herb linter, Brakeman and Bundler Audit are clean. `i18n-tasks normalize` changes nothing.

The Round 5 nit holds: `euros_to_cents` builds a new `ActionController::Parameters` with `merge` and leaves its argument unchanged. `merge` keeps the permitted flag and the other keys, the `warranty_document` upload included. Both callers return its result, and `chattel_amounts_test.rb` and `transaction_amounts_test.rb` still cover the JSON euro input.

No new public method, Law of Demeter chain, N+1 loop or glossary `Avoid:` word in the diff.
