## Round 1 — 2026-10-26 15:02 UTC — d623d9e2

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (clean at review start). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes.

- [ ] Important: the existing test "show paginates recent transactions to the next page" is weakened. It asserted the exact link `transaction_path(oldest)`; it now asserts the bare substring `"/#{oldest.id}"`, which any URL or text ending in that id satisfies. Plan step 6 says "assert with `polymorphic_path(oldest)`". That fails because `oldest` is an in-memory `Transaction` (STI type is set in `before_validation`, the class stays `Transaction`), so `polymorphic_path` yields `/transactions/:id`. `debit_path(oldest)` or `polymorphic_path(Transaction.find(oldest.id))` keeps the exact-link assertion. The deviation is also not recorded in plan.md, as the `account_merges_test.rb` one is — `test/integration/accounts_show_test.rb:126` → fixed (Assert the exact transaction link in the account pagination test)
- [ ] Nit: `Account#transactions` returns every transaction for an unsaved account. `Transaction.by_account(nil)` returns `nil` from the scope body, so Rails falls back to `all`: `Account.new.transactions.to_sql` has no `WHERE`. The old `recent_transactions` SQL matched nothing for a nil id. No current caller passes an unsaved account, but the plan's invariant "returns only transactions where the account is debitor or creditor" does not hold, and `recent_transactions` inherits the change — `app/models/account.rb:63` → fixed (Return no transactions for an account that is not saved)

### Validation

- Full Rails suite: 1483 runs, 4434 assertions, 0 failures, 0 errors, 0 skips.
- System tests: 30 runs, 119 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop: 414 files, 4 `Locale/LiteralMessage` offenses, all in `app/models/transaction.rb`, which this branch does not touch. The cop and the fix for those lines are on `origin/main` (locale-guardrails, #393); the branch is behind `origin/main` and merges cleanly. Rebase before push, or the pre-push RuboCop hook may refuse it.
- Herb: 0 failing offenses (13 hints below the fail level).
- Brakeman: no warnings. Bundler audit: no vulnerabilities.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Same columns as the list, including interest date | `accounts_show_test.rb` "show lists the interest date column" |
| Split sub-rows with amount, category and note | `accounts_show_test.rb` "show renders split sub-rows with amount category and note" |
| Amount opens the transaction, where Edit is available | `accounts_show_test.rb` "show links the amount to the transaction which offers edit" |
| More than 20 transactions paginate; page 2 shows the next | `accounts_show_test.rb` "show paginates recent transactions to the next page" (weakened, see Important) |
| Account without transactions shows an empty table | `accounts_show_test.rb` "show renders an empty table for an account without transactions" |
| Transactions list amount opens the transaction | `transactions_index_test.rb` "index links each transaction to the page for its kind", "index has a title bar with + Nieuw and rows that open the transaction through the amount" (unchanged) |
| Link suggestions, search results and balance table amounts open the transaction | `transaction_links_test.rb` "edit page links a linked transfer's amount to that transfer", "edit page links the source transaction's amount in the balance table", "edit page links a suggested transfer's amount to that transfer"; `transaction_links_controller_test.rb` Index "links each found transfer's amount to that transfer" |

Every test named in plan.md's `## Proof` exists. No test was skipped or deleted. The `account_merges_test.rb` change from `transaction_path` to `polymorphic_path` is recorded in plan.md and asserts the link the page now renders.

### Security

No new input reaches a query: `set_page_and_extract_portion_from` reads `params[:page]` through geared_pagination, and the amount links use `polymorphic_path` on loaded records. Authentication and scoping are unchanged.

### Design

`Account#transactions` is signed in `### Signatures` and carries an inline RBS signature. No Law of Demeter violation added. The per-row `split?`, explicit-split and split-category queries are the cost plan.md's Complexity section accepts; the query-count test proves the page cost does not grow with the account's total transactions. No glossary `Avoid:` word appears.

## Round 2 — 2026-11-06 14:09 UTC — 93dcf856

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (only this `review.md` untracked). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes. Both Round 1 findings hold: the pagination test asserts the exact `polymorphic_path(Transaction.find(oldest.id))`, and `Account#transactions` returns `Transaction.none` for an unsaved account, with the test "transactions is empty for an account that is not saved".

- [ ] Nit: the account page's transactions table lost its card. The old render sat inside `<article>`, which mvpa.css styles as a card (padding, background, border, shadow); the new `<h2>` and table render bare on the page background. Every other section of the account page is an `<article>`, and `/transactions` wraps the same table in `<article class="transactions">`. Wrapping the heading and table in `<article>` keeps the page consistent — `app/views/accounts/show.html.erb:46` → fixed (Wrap the account page transactions table in a card)

### Validation

- Touched test files: 126 runs, 381 assertions, 0 failures, 0 errors, 0 skips.
- Full Rails suite: 1484 runs, 4436 assertions, 0 failures, 0 errors, 0 skips.
- System tests: 30 runs, 119 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop: 414 files, 4 `Locale/LiteralMessage` offenses, all in `app/models/transaction.rb`, which this branch does not touch. The fix is on `origin/main`. The branch is 21 commits behind `origin/main` and merges cleanly; rebase before push.
- Herb: 0 failing offenses (13 hints below the fail level). i18n-tasks normalize: no change.
- Brakeman: no warnings.
- Bundler Audit: fails. The advisory database now lists vulnerabilities in actionpack, actionview, activestorage, activesupport, actionmailbox 8.1.4 (High and Critical among them), addressable 2.9.0, loofah 2.25.2, nokogiri 1.19.4, rack 3.2.7, rails-html-sanitizer 1.7.1 and sqlite3 2.10.1. This branch does not touch `Gemfile.lock`, and `origin/main` pins the same versions, so the failure predates this branch. Per playbook rule 25 it needs its own fix branch; this branch then rebases on top. The pre-push hook runs Bundler Audit, so a push from this branch is refused until then.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Same columns as the list, including interest date | `accounts_show_test.rb` "show lists the interest date column" |
| Split sub-rows with amount, category and note | `accounts_show_test.rb` "show renders split sub-rows with amount category and note" |
| Amount opens the transaction, where Edit is available | `accounts_show_test.rb` "show links the amount to the transaction which offers edit" |
| More than 20 transactions paginate; page 2 shows the next | `accounts_show_test.rb` "show paginates recent transactions to the next page" (exact link restored) |
| Account without transactions shows an empty table | `accounts_show_test.rb` "show renders an empty table for an account without transactions" |
| Transactions list amount opens the transaction | `transactions_index_test.rb` "index links each transaction to the page for its kind", "index has a title bar with + Nieuw and rows that open the transaction through the amount" (unchanged) |
| Link suggestions, search results and balance table amounts open the transaction | `transaction_links_test.rb` "edit page links a linked transfer's amount to that transfer", "edit page links the source transaction's amount in the balance table", "edit page links a suggested transfer's amount to that transfer"; `transaction_links_controller_test.rb` Index "links each found transfer's amount to that transfer" |

Every test named in plan.md's `## Proof` exists. No test was skipped, deleted or weakened.

### Security

No new input reaches a query: `set_page_and_extract_portion_from` reads `params[:page]` through geared_pagination, and the amount links use `polymorphic_path` on loaded records. Authentication and scoping are unchanged. The dependency advisories above are pre-existing and outside this diff.

### Design

`Account#transactions` is signed in `### Signatures` and carries an inline RBS signature; the `persisted?` guard from Round 1 is the only addition to the signed body. No Law of Demeter violation added. The per-row split queries are the cost plan.md's Complexity section accepts, and the query-count test proves the page cost does not grow with the account's total transactions. No glossary `Avoid:` word appears.

## Round 3 — 2026-11-07 07:40 UTC — e9b0b62a

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (only this `review.md` untracked). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes. The branch is rebased onto current `origin/main` (6ce87142, 0 commits behind). The Round 2 finding holds: the heading and table render inside `<article>`, proven by "show renders the transactions heading and table inside a card".

Nothing found.

### Validation

- Touched test files: 127 runs, 385 assertions, 0 failures, 0 errors, 0 skips.
- Full Rails suite: 1518 runs, 4492 assertions, 0 failures, 0 errors, 0 skips.
- System tests: 32 runs, 173 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop: 418 files, no offenses. The Round 1 and 2 `Locale/LiteralMessage` offenses are gone after the rebase.
- Herb: 0 failing offenses (13 hints below the fail level). i18n-tasks normalize: no change.
- Brakeman: no warnings.
- Bundler Audit: no vulnerabilities. The Round 2 advisories are fixed on `origin/main` (#406), and this branch now sits on top of it.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Same columns as the list, including interest date | `accounts_show_test.rb` "show lists the interest date column" |
| Split sub-rows with amount, category and note | `accounts_show_test.rb` "show renders split sub-rows with amount category and note" |
| Amount opens the transaction, where Edit is available | `accounts_show_test.rb` "show links the amount to the transaction which offers edit" |
| More than 20 transactions paginate; page 2 shows the next | `accounts_show_test.rb` "show paginates recent transactions to the next page" |
| Account without transactions shows an empty table | `accounts_show_test.rb` "show renders an empty table for an account without transactions" |
| Transactions list amount opens the transaction | `transactions_index_test.rb` "index links each transaction to the page for its kind", "index has a title bar with + Nieuw and rows that open the transaction through the amount" (unchanged) |
| Link suggestions, search results and balance table amounts open the transaction | `transaction_links_test.rb` "edit page links a linked transfer's amount to that transfer", "edit page links the source transaction's amount in the balance table", "edit page links a suggested transfer's amount to that transfer"; `transaction_links_controller_test.rb` Index "links each found transfer's amount to that transfer" |

Every test named in plan.md's `## Proof` exists. No test was skipped, deleted or weakened.

### Security

No new input reaches a query: `set_page_and_extract_portion_from` reads `params[:page]` through geared_pagination, and the amount links use `polymorphic_path` on loaded records. Authentication and scoping are unchanged.

### Design

`Account#transactions` is signed in `### Signatures` and carries an inline RBS signature. No Law of Demeter violation added. The per-row split queries are the cost plan.md's Complexity section accepts, and the query-count test proves the page cost does not grow with the account's total transactions. No glossary `Avoid:` word appears; "orders" in a test name means sorting, not a delivery.

Follow-up for a separate branch, not a finding for this one: `Account#transactions_exist?` (`app/models/account.rb:190`) still holds its own debitor-or-creditor SQL, and the `page:` local of `shared/_recent_transactions` has no caller left after this change. Plan.md keeps both out of scope.
