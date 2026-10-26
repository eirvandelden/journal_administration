# Review: split-form-amount-first

## Round 1 — 2026-10-26T14:12Z — 3cc37cd

No findings.

- Bugs: the amount label, field and error block moved as one unit; the `financial_transaction` error stays first and the note stays last. The amount error `<p>` still follows the `field_with_errors` wrapper of the amount input.
- Security: no new input, parameter or query. Strong parameters are unchanged.
- Compliance: "the add-split form shows the amount field before the category field, and the note field last" → `test/integration/transaction_splits_test.rb` "add-split form asks amount, then category, then note". Both tests named in `plan.md` `## Proof` exist. No existing test was weakened, skipped or deleted.
- Design: no Ruby method changes, no call chain, no query in a loop, no glossary `Avoid:` word.
- Checks: `bin/rails test` 1349 runs, 0 failures; rubocop and herb-lint clean on the touched files.
