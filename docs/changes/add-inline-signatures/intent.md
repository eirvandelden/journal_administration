# Intent: Add inline RBS signatures

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no.

## Problem

Since `92596a5e Updates` (2026-10-26) bumped `rubocop-eirvandelden`, the `ci / lint` job on `main` fails. The shared config now demands an inline RBS `#:` signature on every public method and `attr_*`, and a type on every Struct and Data attribute. Rubocop reports 410 offenses in 120 files: 391 missing method signatures, 15 untyped Struct attributes, 3 `Struct.new` calls with a block, and 1 comment spacing offense. Every branch inherits the red lint job.

Ten of those offenses sit in run-once scripts: `db/data` (8), `db/cable_migrate` (1) and `db/queue_migrate` (1). The gem already excludes `db/migrate` for that reason ("run once and never called from code"), but not these folders.

## Proposed outcome

`bundle exec rubocop` reports no offenses, and `ci / lint` on `main` is green again once this change merges. Each public method, `attr_*` and Struct attribute in the app carries an inline signature that states its real types, so a reader learns what goes in and what comes out.

## Affected users and systems

- Developers and agents working in this repository, and the CI lint job.
- `rubocop-eirvandelden`, through a separate change (see Out of scope).
- The app's runtime behaviour does not change.

## Constraints

- No linter disable comments, no `# rbs_inline: disabled` to dodge the cops, and no edit to this repo's `.rubocop.yml` to pass (playbook rule 2, §7a).
- No new dependency. Approved permission: `bundle update rubocop-eirvandelden`, once the gem change is merged. No other gem, system tool, dropping migration or deploy file is approved.
- The gem change must be merged before this change can bump the gem. If it is not merged when delivery reaches the bump, stop and ask Etienne.
- Signatures use real types (`String`, `Integer`, `Account`, `ActiveRecord::Relation`, `bool`, `void`). `untyped` only where the value truly varies.
- The three `Struct.new` rewrites keep behaviour. Existing tests cover them; a moved method without a covering test gets one.

## In scope

- `#:` signatures on every public method and `attr_*` that rubocop flags in `app/` (controllers, helpers, jobs, models, tools, channels).
- `#:` types on the 15 flagged Struct attributes.
- Rewrite `Struct.new ... do` in `TodosController::Page`, `Importing::AlbertHeijn::PackingSlip::Line` and `Search` as the cop says: keep the `Struct.new` call, move the block's methods into a class body written after it.
- The one comment spacing offense.
- `script/admin/prepare-backup`: a signature on `Backup.create`.
- Bump `rubocop-eirvandelden` to the release that excludes the run-once folders, as the last commit.

## Out of scope

- The `rubocop-eirvandelden` change itself: extend the `db/migrate` exclusion of `Style/RbsInline/MissingTypeAnnotation` to `db/*_migrate` and `db/data`. It is its own intent in that repository.
- Signatures on the run-once scripts in `db/data`, `db/cable_migrate` and `db/queue_migrate`.
- Signatures on private methods (the gem asks only for public ones).
- Tests: `test/` is excluded by the gem.
- A type checker (Steep, `rbs validate`) in CI, and generated `sig/` files.
- Converting Structs to `Data.define`.

## Acceptance criteria

- On this branch, after the gem bump, `bundle exec rubocop` reports `0 offenses`.
- `ci / lint` on the pull request is green.
- New signatures read like the existing `Category.add_household_expense`, `#: (String name) -> Category`: the types name the domain class, not `untyped`.
- `TodosController#index` reads `#: () -> void`.
- `Search` still returns the same results for the same query; `TodosController` still paginates the same; a packing slip still reads the same lines, amounts and discounts. The full test suite stays green.
- `db/data/20260315000002_seed_account_aliases.rb` gains no signature and raises no offense.

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

## Open questions

None.
