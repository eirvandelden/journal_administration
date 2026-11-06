# Review: bump-rails-8-1-4-1

## Round 1 — 2026-11-06T21:00:13Z — 083e7dbd

Checks run on this SHA: `bundle exec rubocop` no offenses (418 files); `bundle exec bundler-audit check` no vulnerabilities; `bin/rails test` 1494 runs, 0 failures; `bin/rails test:system` 32 runs, 0 failures (the date-flaky budget test passed today); `bundle exec brakeman --no-pager -q` 0 warnings; `bin/rails runner 'puts Rails.version'` prints 8.1.4.1. The lockfile diff holds only the A1 gems plus `addressable` 2.9.2 and `sqlite3` 2.10.2, all platform variants kept; `Gemfile` and `.rubocop.yml` unchanged. The `untyped` allow-list check exits 0. No escape hatch in `app/` or `script/`.

Compliance: each acceptance criterion is proved by the checks above; the pre-push hook criterion is proved by the push of this branch. No test was added, weakened, skipped or deleted, as the plan says. The Struct reopens keep their constructors; their tests are green.

Design: every public method in scope carries a signature (rubocop enforces it). No new call chain, query or glossary `Avoid:` word in the added lines. Spot-checked unions and nilability against bodies and callers: `Account#recent_transactions` (`limit: nil` caller), `Product.resolve_by_name` (`Product?` from the rescue), `Accountable#move_counterparty` (`save!` → `true`), `DateRange.from_dates`, `User#deactivate`, `Receipt#rewrite_payment_splits`, `Search#results` — all correct.

- [ ] Nit: Replacing `# @return [void]` with `#` plus the signature left two blank comment lines in a row above 49 methods in 13 files, for example "# Lists all accounts with pagination", `#`, `#`, `#: () -> void`; main had none of these. Drop one of each pair. — `app/controllers/accounts_controller.rb:7` → fixed (Drop the doubled blank comment line above the annotated methods)
- [ ] Nit: `Todo::Item#date` is typed `ActiveSupport::TimeWithZone`, but `transaction_items` passes `t.booked_at`, and `transactions.booked_at` is nullable (`db/schema.rb:271`; `Appropriation#charges` handles undated payments). Type it `ActiveSupport::TimeWithZone?`. — `app/models/todo.rb:16` → fixed (Type Todo::Item#date as nullable)
- [ ] Nit: The escape-hatch Proof command exits 1 on this branch: `git diff origin/main` includes `plan.md`, which names the forbidden markers in prose (lines 136, 152, 155, 237). The code itself is clean. Scope the command to `-- app script lib config` so the check proves what it says while the change folder exists. — `docs/changes/bump-rails-8-1-4-1/plan.md:237` → fixed (Scope the escape-hatch proof command to the code directories)

## Round 2 — 2026-11-06T21:06:42Z — 0fee6258

Checks run on this SHA (Ruby 4.0.7): `bundle exec rubocop` no offenses (418 files); `bundle exec bundler-audit check` no vulnerabilities; `bundle exec brakeman --no-pager -q` no warnings; `bin/rails test` 1494 runs, 0 failures, tracked tree unchanged afterwards. System tests not rerun: the three commits since round 1 change comments and `plan.md` only. The escape-hatch and `untyped` Proof commands both exit 0. `git diff origin/main...HEAD` touches no `Gemfile`, `.rubocop.yml`, `test/`, `db/`, `config/`, `lib/` or `.github/` file; the lockfile moves exactly the A1 gems plus `addressable` and `sqlite3`.

Round 1 fixes verified: no doubled `#` line remains in `app/` or `script/`; `Todo::Item#date` is `ActiveSupport::TimeWithZone?`, and `Todo#items` sorts by `-item.date.to_i`, which takes nil; the escape-hatch command is scoped to the code directories.

Bugs and Security: every removed line in `app/` and `script/` is a YARD type tag, a blank comment line, an `attr_reader` split into typed lines, a Struct reshaped into a reopened class, or the misplaced `#:` above `unlinked_deliveries`. No code path changes. Brakeman and the audit are clean.

Compliance: the acceptance criteria for the audit, rubocop, tests and Brakeman are met by the checks above. The pre-push hook criterion is not yet proved: the branch has never been pushed (`git ls-remote origin bump-rails-8-1-4-1` is empty), and plan step 10 requires a rebase first, because main has moved (see the finding). No test was added, weakened, skipped or deleted.

Design: further spot-checks against bodies, callers and `db/schema.rb`: `Chattel#purchased_at` (`datetime` column, `TimeWithZone?`), `ProductType#monthly_totals` (`issued_on` is a `date`, `Hash[Date, Totals]`), `Importing::ING::Row#date` (`DateTime.parse`), `Search#results` (the five groups `compute_results` builds), `Budget#plan` (the only caller passes cents), `ChartsHelper` `Numeric` data (the dashboard view passes euro floats), `Mergeable#merge` (the only caller passes an Array). All correct. No new call chain, query loop or glossary `Avoid:` word.

- [ ] Important: The branch is not rebased on current main. `origin/main` is 6 commits ahead (merge b35ab2f8, PR #403, `feat: link appropriation charges to their payment`, which edits `app/models/transaction.rb`, also changed here). Plan step 10 and playbook rule 20 require a fetch and a rebase before the push, then a rerun of steps 7 and 8 and of the pre-push hook on the rebased tree. A trial `git merge-tree` against `origin/main` reports no conflict, and main's two new `whole_payment` methods already carry signatures, so the rebase should stay clean; it still has to be done and checked. — `docs/changes/bump-rails-8-1-4-1/plan.md:217` → fixed (rebased onto origin/main 30b2f618; rubocop, bundler-audit, Brakeman and 1500 tests green on the rebased tree)

## Round 3 — 2026-11-06T21:20:00Z — dba61ce3

Checks run on this SHA (Ruby 4.0.7, worktree `bin/` first on `PATH`, bootsnap cache cleared): `bundle exec rubocop` no offenses (418 files); `bundle exec bundler-audit check` no vulnerabilities; `bundle exec brakeman --no-pager -q` no warnings; `bin/rails test` 1500 runs, 0 failures; `bin/rails test:system` 32 runs, 0 failures; `bin/rails runner 'puts Rails.version'` prints 8.1.4.1. The escape-hatch and `untyped` Proof commands both exit 0. `git diff origin/main...HEAD` touches no `Gemfile`, `.rubocop.yml`, `test/`, `db/`, `config/`, `lib/` or `.github/` file. Tracked tree clean afterwards.

Round 2 fix verified: `origin/main` (30b2f618) is an ancestor of HEAD, and `git fetch` shows main has not moved since. `git range-diff` against the round-2 commits shows only context changes in `app/models/transaction.rb` (main's `whole_payment` methods, already signed) and a smaller lockfile commit. No signature was lost or changed in the rebase.

Bugs and Security: unchanged from round 2; the rebase adds no code. Lockfile: main already took `sqlite3` 2.10.2 (740be36b, `Bump sqlite3 to 2.10.2 for GHSA-4fqr-96q8-xrfx`), so the branch now moves exactly the A1 gems plus `addressable`. That is inside the plan's allowed list.

Compliance: the pre-push hook criterion is still proved only by the push, which follows this round. No test was added, weakened, skipped or deleted.

Design: no new findings.

- [ ] Nit: Commit 6cfe56f0 is titled `Bump addressable and sqlite3 for security advisories`, but after the rebase it changes only `addressable` (2.9.0 → 2.9.2); `sqlite3` 2.10.2 came from main's 740be36b. Reword it to `Bump addressable for security advisories`. The branch is not on `origin` yet, so the reword needs no force-push. — `Gemfile.lock` (commit 6cfe56f0) → fixed (Bump addressable for security advisories)
