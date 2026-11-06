# Delivery: link-appropriation-charges

## Behaviour delivered

The amount of each charge on the appropriation show page links to the payment it belongs to. A whole-payment charge links to its own transaction. A split part links to the transaction it splits. From there Etienne changes or removes the charge. An appropriation with no charges still shows "Nothing is charged to this appropriation yet." and no link.

The plan added `whole_payment` to `Transaction` and `TransactionSplit`, so the view sends one message and holds no type check. The intent had expected no model change; the agreed behaviour did not change.

## Evidence

- Integration tests render the real page and assert the link in the amount cell for a whole payment and for a split part, and the empty state with no link. A query-count test shows one split part and three split parts run the same number of queries.
- Unit tests cover `Transaction#whole_payment` and `TransactionSplit#whole_payment`.
- Each new test failed before the code and passes after it.
- No manual browser check was done. The integration and system tests render the page through the full stack.

## Check results

- `bin/rails test`: 1500 runs, 0 failures.
- `bin/rails test:system`: 32 runs, 0 failures.
- Brakeman: no warnings. Herb on the changed view: 0 offenses. `i18n-tasks normalize`: no locale diff.
- Rubocop on the touched files: 3 offenses, all `Style/RbsInline/MissingTypeAnnotation` on old lines 72, 77 and 86 of `app/models/transaction.rb`. They fail on `main` too, and `add-inline-signatures` fixes them.
- Bundler Audit: fails on `sqlite3` 2.10.1 (GHSA-4fqr-96q8-xrfx), also on `main`. The fix is `sqlite3` 2.10.2 or later, in a separate change.
- The commit hooks and the pre-push hooks were skipped with `--no-verify`, on Etienne's explicit consent, because of those two failures. CI will show the same two failures.

## Review outcome

One Claude round, no findings: every acceptance criterion and Proof test is in the diff, the signatures are in the plan, and there is no N+1 query. Codex review was not enabled.

## Environment note

The shared `appkit` and `mvpa.css` gem checkouts under the rv gems directory had moved to other revisions. With Etienne's consent they were reset to the pinned commits `9b5b30d` and `2be440b`. Another session that needs the newer revisions must run `bi` again.
