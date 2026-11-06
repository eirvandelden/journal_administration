# Review: Bump gems with open security advisories and clear rubocop on main

## Round 1 — 2026-11-06T20:28Z — 3a425a96

No `REVIEW.md` or `REVIEW.local.md` in the repository; the default Bugs, Security, Compliance and Design passes apply.

Checks run on 3a425a96 against `origin/main` (288facbe): `bundle exec rubocop` 418 files, no offenses; `bundle exec bundler-audit check --update` no vulnerabilities; `bundle exec brakeman --no-pager -q` no warnings; herb linter passes; `bin/rails test` 1494 runs, 0 failures, 0 skips; `bin/rails test:system` 32 runs, 0 failures; `rbs-inline --opt-out` over `app db script/admin/prepare-backup` and `rbs parse` both exit 0; the plan's lockfile check prints "Lockfile OK" with only advisory gems changed; the plan's comment-only check passes (the only non-comment lines are trailing `#:` on `attr_reader`); `Gemfile` and `.rubocop.yml` are unchanged; no `rubocop:disable` added.

Compliance:

- Bundler Audit reports no vulnerabilities → `bundle exec bundler-audit check --update` (run above).
- `bundle exec rubocop` reports no offenses → `bundle exec rubocop` (run above).
- Full suite, system tests, rubocop, herb and brakeman pass → all run above, green.
- `Gemfile.lock` diff holds only the advisory gems and their direct dependencies → lockfile check (run above).
- Plan `## Proof` tests exist and are unchanged: `test/models/importing/albert_heijn/packing_slip_test.rb:24`, `test/models/search_test.rb:91`, `test/integration/pagination_navigation_test.rb:63`. No test file changes in the diff.
- "The app behaves as before" → step 14 manual checks: missing (see the Important finding).

Security: patch bumps only, inside current minors; no new code paths. Design: no Law of Demeter or N+1 changes (signatures are comments; the three Struct moves keep their bodies nested in the same owner). No glossary `Avoid:` word in added lines.

- [ ] Important: No recorded evidence of plan step 14's manual check (PDF proof of purchase served inline, chattel notes with `<script>` and `javascript:` sanitized, todo page and search dialog render). The plan names it as the only proof for Active Storage serving, multipart upload and sanitizing, which have no tests, and §7a asks for recorded evidence. Run it and record the results in the change folder or the pull request body. — `docs/changes/bump-rails-security-advisories/plan.md:223` → dismissed: manual check done 2026-11-06 on the branch at e58aa825 with rails 8.1.4.1 and rack 3.2.8 (server on 127.0.0.1:3001, dev DB copy, scratch user, curl). Upload: a multipart PATCH of a PDF proof of purchase returned 302; the show page linked the blob; the Active Storage redirect returned 200 application/pdf and the bytes were identical to the upload. Sanitizer: chattel notes with a script tag, a javascript: link and an onerror image rendered as `alert(1)safe <a>x</a> <img src="x"> line` (no script element, no javascript: href, no onerror). Pages /, /transactions, /todo, /chattels and /searches?q=ah returned 200. No browser was used; the app was driven over HTTP. Evidence goes in the PR body too
- [ ] Nit: `Importing::ING::Row#initialize` signature `(date: DateTime, amount: Integer, **untyped)` turns nine required keywords into an optional rest, so the RBS no longer says `initiator_name:`, `code:` and the others are required. List each keyword, `untyped` where the body does not settle it. — `app/models/importing/ing/row.rb:43` → dismissed: RBS inline has no valid multi-line form (rbs-inline emits invalid RBS, rubocop reports InvalidTypes), and the full keyword list exceeds the 120-character line limit on one line
- [ ] Nit: `ChargeToAppropriation.call` hides the required `server_context:` in `**untyped`, unlike the plan's MCP tool convention that the other 22 tools follow (`server_context: untyped`). — `app/tools/assistant/charge_to_appropriation.rb:19` → dismissed: the signature with `server_context: untyped` is 140 characters; RBS inline has no valid multi-line form, so it cannot fit the 120-character limit
- [ ] Nit: `ChargeToAppropriation.chargeable_in` signature `(Transaction, Integer?)` has no parameter names; every other signature in the diff names them (`Transaction transaction, Integer? transaction_split_id`). — `app/tools/assistant/charge_to_appropriation.rb:34` → dismissed: the named-parameter signature is 121 characters, over the 120-character limit, and RBS inline has no valid multi-line form
- [ ] Nit: `Todo::Item#date` is typed `ActiveSupport::TimeWithZone`, but `transactions.booked_at` is a nullable `datetime` with no presence validation, and `transaction_items` passes it through, so the schema says `ActiveSupport::TimeWithZone?` (as `Chattel#purchased_at` already does). — `app/models/todo.rb:21` → fixed (style: type Todo::Item#date as nullable)

## Round 2 — 2026-11-06T21:10Z — e58aa825

Reviewed e58aa825 against `origin/main` (b35ab2f8; merge base 288facbe). The only commit since round 1 is `style: type Todo::Item#date as nullable`, a one-comment change; `Todo` builds items from `booked_at` (nullable) and `created_at`, so `ActiveSupport::TimeWithZone?` is true. All round 1 findings are closed.

`origin/main` gained `link-appropriation-charges` (#403) since the merge base. `git merge-tree` merges it with no conflict, and rubocop on the merged `app/models/transaction.rb`, `app/models/transaction_split.rb` and `app/models/concerns/chargeable.rb` reports no offenses (main's new `whole_payment` methods already carry signatures).

Checks run on e58aa825: `bundle exec rubocop` 418 files, no offenses; `bundle exec bundler-audit check --update` no vulnerabilities; `bundle exec brakeman --no-pager -q` no warnings; herb linter exits 0; `bin/rails test` 1494 runs, 0 failures, 0 skips; the plan's comment-only check prints only the trailing `#:` on `attr_reader` lines, as in round 1; `Gemfile` and `.rubocop.yml` unchanged; no `rubocop:disable` added.

Compliance: unchanged from round 1; every acceptance criterion is met, and step 14's manual check is recorded in round 1's dismissal. Security: no new code paths. Design: no new public method, Law of Demeter, N+1 or glossary `Avoid:` issue.

No findings.
