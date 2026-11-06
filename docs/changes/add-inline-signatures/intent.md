# Intent: Add inline RBS signatures

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no.

## Problem

Since `92596a5e Updates` (2026-10-26) bumped `rubocop-eirvandelden`, the `ci / lint` job on `main` fails. The shared config now demands an inline RBS `#:` signature on every public method and `attr_*`, and a type on every Struct and Data attribute. Rubocop reports 410 offenses in 120 files: 391 missing method signatures, 15 untyped Struct attributes, 3 `Struct.new` calls with a block, and 1 comment spacing offense. Every branch inherits the red lint job.

Ten of those offenses sit in run-once scripts: `db/data` (8), `db/cable_migrate` (1) and `db/queue_migrate` (1). The gem already excludes `db/migrate` for that reason ("run once and never called from code"), but not these folders.

## Proposed outcome

`bundle exec rubocop` reports no offenses, and `ci / lint` on `main` is green again once this change merges. Each public method, `attr_*` and Struct attribute in the app carries an inline signature that states its real types, so a reader learns what goes in and what comes out.

## Affected users and systems

- Developers and agents working in this repository, and the CI lint job.
- `rubocop-eirvandelden`: this delivery also changes the gem, in its own worktree and draft pull request in that repository.
- The app's runtime behaviour does not change.

## Constraints

- No linter disable comments, no `# rbs_inline: disabled` to dodge the cops, and no edit to this repo's `.rubocop.yml` to pass (playbook rule 2, §7a).
- No new dependency. Approved permissions: `bundle update rubocop-eirvandelden` once the gem change is merged, and `bundle update sqlite3`. No other gem, system tool, dropping migration or deploy file is approved.
- The gem change must be merged before this change can bump the gem. Only Etienne merges it. When delivery reaches the bump and the gem pull request is not merged, stop and ask Etienne.
- Pushes wait until every lefthook pre-push check passes. Never bypass lefthook (`LEFTHOOK=0`, `--no-verify`). Run `npm install` in the worktree first.
- Signatures use real types (`String`, `Integer`, `Account`, `ActiveRecord::Relation`, `bool`, `void`). `untyped` only where the value truly varies.
- The three `Struct.new` rewrites keep behaviour. Existing tests cover them; a moved method without a covering test gets one.

## In scope

- `#:` signatures on every public method and `attr_*` that rubocop flags in `app/` (controllers, helpers, jobs, models, tools, channels).
- `#:` types on the 15 flagged Struct attributes.
- Rewrite `Struct.new ... do` in `TodosController::Page`, `Importing::AlbertHeijn::PackingSlip::Line` and `Search` as the cop says: keep the `Struct.new` call, move the block's methods into a class body written after it.
- The one comment spacing offense.
- `script/admin/prepare-backup`: a signature on `Backup.create`.
- In `rubocop-eirvandelden` (`~/Developer/rubocop-eirvandelden`), in its own worktree: extend the `db/migrate` exclusion of `Style/RbsInline/MissingTypeAnnotation` in `config/rails.yml` to `db/*_migrate` and `db/data`, with tests in `test/shared_configuration_test.rb` and a `CHANGELOG.md` line, and open a draft pull request there.
- Bump `sqlite3` to 2.10.2 or newer (GHSA-4fqr-96q8-xrfx), as its own commit.
- Bump `rubocop-eirvandelden` to the merged gem change, as the last commit.

## Out of scope

- Signatures on the run-once scripts in `db/data`, `db/cable_migrate` and `db/queue_migrate`.
- Signatures on private methods (the gem asks only for public ones).
- Tests: `test/` is excluded by the gem.
- Merging the gem pull request: Etienne merges it.
- Other gem updates than `sqlite3` and `rubocop-eirvandelden`.
- A type checker (Steep, `rbs validate`) in CI, and generated `sig/` files.
- Converting Structs to `Data.define`.

## Acceptance criteria

- On this branch, after the gem bump, `bundle exec rubocop` reports `0 offenses`.
- `ci / lint` on the pull request is green.
- New signatures read like the existing `Category.add_household_expense`, `#: (String name) -> Category`: the types name the domain class, not `untyped`.
- `TodosController#index` reads `#: () -> void`.
- `Search` still returns the same results for the same query; `TodosController` still paginates the same; a packing slip still reads the same lines, amounts and discounts. The full test suite stays green.
- `db/data/20260315000002_seed_account_aliases.rb` gains no signature and raises no offense.
- In the gem, a Rails project gets no `MissingTypeAnnotation` offense for a public method in `db/data/x.rb`, `db/cable_migrate/x.rb` or `db/queue_migrate/x.rb`, and still gets one in `app/models/x.rb`.
- `bundle exec bundler-audit check` reports no vulnerabilities, and `ci / scan_ruby` on the pull request is green.

## Decisions

- Treat it as a chore — the cause is clear: a gem bump turned lint red.
- Exclude the run-once scripts in the gem, not here — same reason as `db/migrate`, one rule for all run-once scripts.
- Use real types, `untyped` rarely — a signature full of `untyped` tells a reader nothing.
- Follow the cop's fix for `Struct.new` with a block — smallest change, same behaviour; the cop names this exact fix.
- Annotate `script/admin/prepare-backup` here — it runs again and again, like app code, so it is not run-once.
- Bump the gem in this change — lint stays red on every branch until both land, so one green PR here is the clearest finish.
- Deliver autonomously — no reason given.
- Approve `bundle update rubocop-eirvandelden` up front — it is the step that turns lint green.
- Review with Claude only — the change is comments plus three small Struct moves.
- Hold pushes until every pre-push check passes — no lefthook bypass; nobody needs the branch earlier. (Plan stage escalation, 2026-11-06.)
- Bump `sqlite3` in this change — no reason given. (Plan stage escalation, 2026-11-06.)
- Change the gem from this delivery, not as a separate intent — it keeps the agreed design, exclusion in the gem. (Plan stage escalation, 2026-11-06.)
- Keep `**String` on `Importing::ING::Row#initialize` and `**untyped` on `Assistant::ChargeToAppropriation.call`, each with a one-line reason comment — the full keyword form exceeds 120 characters and `#|` continuation fails `InvalidTypes`. (Implement stage escalation, 2026-11-06.)

## Open questions

None.
