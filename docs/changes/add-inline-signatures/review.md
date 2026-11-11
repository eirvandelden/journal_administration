# Review: add-inline-signatures

## Round 1 — 2026-11-06T20:05Z — 3e4bb7e9

- [ ] Important: The `**String` shortcut on `Importing::ING::Row#initialize` has no one-line reason comment above it. The intent decision (2026-11-06 implement escalation) and the plan's second amendment both require one — `app/models/importing/ing/row.rb:51` → fixed (docs: explain the two keyword-splat signatures)
- [ ] Important: The `**untyped` shortcut on `Assistant::ChargeToAppropriation.call` has no one-line reason comment above it. This breaks the same intent decision, and the plan's invariant that a new `untyped` appears only in the two allowed places or with a reason comment — `app/tools/assistant/charge_to_appropriation.rb:19` → fixed (docs: explain the two keyword-splat signatures)

Checks on 3e4bb7e9: `bundle exec rubocop` 419 files, no offenses; `bundler-audit` no vulnerabilities; Brakeman 0 warnings; herb lint passes; `bin/rails test` 1498 runs, 0 failures, 0 errors, 0 skips. System tests not run.

Compliance:

- `0 offenses` after the gem bump: met (rubocop above). The gem revision `d91402e` is on `rubocop-eirvandelden` `origin/main`.
- `ci / lint` and `ci / scan_ruby` green on the pull request: not checkable before `deliver` opens it.
- Signatures name the domain class: met. Sampled `Dashboard`, `DateRange`, `Cents`, `Cents::Type`, `Chattel`, `Splittable`, `Mergeable`, `Account`, `Appropriation`, `Group`, `Budget`, `Receipt`, `BudgetHelper`, `MoneyHelper`, `TodosHelper`, `ClassifyProduct` and `ListUnlinkedDeliveries` against their bodies and `db/schema.rb`; each matches. New `untyped` appears only on `server_context`, `**untyped options` and the finding above.
- `TodosController#index` reads `#: () -> void`: met. Every signed controller method is a CRUD action with `() -> void`.
- Search, todo paging and packing slip behaviour unchanged: `test/controllers/todos_controller_page_test.rb` (the three named tests) and `a line's paid amount is its full amount less its bonus` exist; the full suite is green.
- `db/data/20260315000002_seed_account_aliases.rb` unchanged: met (empty diff, no offense).
- Gem tests for `db/data`, `db/*_migrate` and `app/models`: three tests in `test/shared_configuration_test.rb` in `d91402e`.
- `bundler-audit` clean: met. `Gemfile.lock` changes only `sqlite3`, the six approved security bumps (with their Rails frameworks) and the `rubocop-eirvandelden` revision.
- No test weakened, skipped or deleted; no disable comment, `@rbs skip` or `.rubocop.yml` edit; nothing in `db/`, `config/` or `.github/` changed.

Design: the three reopened Structs match the plan's shapes; no Law of Demeter violation, N+1 loop or glossary `Avoid:` word is introduced.

## Round 2 — 2026-11-06T20:11Z — 22eb4f74

- [ ] Important: `Assistant::ImportAlbertHeijnMail.describe` types its basket as `Importing::AlbertHeijn::BasketMail`. That is a module with only `self.parse`. No basket is a `BasketMail`, and no reader includes it. `BasketMail.parse` itself signs the real type, `(PackingSlip | OlderPackingSlip | OrderConfirmation)?`, and `call` returns early on nil. The signature names a type that no value has, against the intent's "states its real types". Use `Importing::AlbertHeijn::PackingSlip | Importing::AlbertHeijn::OlderPackingSlip | Importing::AlbertHeijn::OrderConfirmation`, or the short constant names if the line gets too long — `app/tools/assistant/import_albert_heijn_mail.rb:27` → fixed (docs: type the imported basket as untyped with its reason)

Round 1's two findings hold: both reason comments sit directly above their signatures, and the count "nine other keywords" on `Importing::ING::Row#initialize` is correct.

Checks on 22eb4f74: `bundle exec rubocop` 419 files, no offenses; `bundler-audit` no vulnerabilities; Brakeman 0 warnings; `bin/rails test` 1498 runs, 0 failures, 0 errors, 0 skips. Herb lint and system tests not run (no view changes).

Compliance:

- `0 offenses` after the gem bump: met (rubocop above).
- `ci / lint` and `ci / scan_ruby` green on the pull request: not checkable before `deliver` opens it.
- Signatures name the domain class: met, except the finding above. Sampled `Accountable`, `Account#managed_owner`, `DateRange`, `Importing::ING::Row` (against `test/fixtures/files/test_import.csv`: quoted empty fields read as `""`, so `String` holds), `Searchable`, `Cents.split_decimals`, `Chattel#warranty_proof`, `Mergeable#merge`, the three basket readers' `attr_reader` types (all build `PackingSlip::Line` through `Reading#lines_from`) and every `Assistant` tool signature.
- New `untyped`: only `server_context`, `**untyped options` and `ChargeToAppropriation.call`, which now has its reason comment.
- `TodosController#index` reads `#: () -> void`: met.
- Search, todo paging and packing slip behaviour unchanged: the named tests exist; the full suite is green.
- `db/data/20260315000002_seed_account_aliases.rb` unchanged: met; `git diff origin/main --stat -- db config .github .rubocop.yml` is empty.
- No disable comment, `rbs_inline: disabled` or `@rbs skip` in code; no test weakened, skipped or deleted.

Design: no Law of Demeter violation, N+1 loop or glossary `Avoid:` word is introduced. Every public method in the diff has a signature (rubocop enforces it).

## Round 3 — 2026-11-11T13:39Z — 8e47e064

Nothing found. Reviewed against the rescoped `intent.md` and `plan.md` (accepted 2026-11-11) and `git diff origin/main...HEAD`.

Checks on 8e47e064: `bundle exec rubocop` 468 files, no offenses; `git diff origin/main -- Gemfile.lock` empty; `bundler-audit` no vulnerabilities; Brakeman 0 warnings; `bin/rails test` 1635 runs, 0 failures, 0 errors, 0 skips. Herb lint and system tests not run (no view changes).

Compliance:

- Two characterisation tests green: met. `test/controllers/todos_controller_page_test.rb` holds `the last page knows it is last`, `a page before the last is before last` and `the next page number is one more`; `test/models/importing/albert_heijn/packing_slip_test.rb` holds `a line's paid amount is its full amount less its bonus`. Argument order matches the `Page` and `Line` Struct members.
- `0 offenses` and no lockfile change: met (checks above).
- Each of the three `untyped` signatures has a reason comment directly above it: met. The `grep -B1` check shows a reason line above `Row#initialize`, `ImportAlbertHeijnMail.describe` and `ChargeToAppropriation.call`; `#:` stays the last line above `def` in all three. The count "nine other CSV columns" is correct (eleven keywords, two typed).
- `Todo::Item` YARD matches the Struct types: met. `todo.rb` builds `:transaction`, `:account` and `:product` items with `booked_at`/`created_at` dates.
- bundler-audit, Brakeman and the full suite green: met.
- Only this change in the pull request: met. `git diff origin/main --stat` lists only the files in `## Files that change`.
- No test weakened, skipped or deleted; no disable comment, `.rubocop.yml`, `db/`, `config/` or `.github/` change.

Design: no new public method, so no unsigned signature. No Law of Demeter violation or N+1 loop (comments and tests only). No glossary `Avoid:` word in the new comments or test names.
