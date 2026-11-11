# Intent: Add inline RBS signatures (rescoped after PR #406)

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-11). Type: chore. Delivery: autonomous. Codex review: no.

## Problem

This branch was meant to turn `ci / lint` green by adding inline RBS signatures. PR #406 (`6ce87142`) did that on `main`: it annotated 410 offenses, reopened the three `Struct.new ... do` classes, added `#: () -> void` to the run-once scripts, and bumped Rails, `rack`, `nokogiri`, `loofah`, `rails-html-sanitizer`, `addressable` and `sqlite3`. `bundle exec rubocop` reports `0 offenses` on `main` with the old `rubocop-eirvandelden` revision.

After rebasing onto `origin/main`, 11 of this branch's commits were dropped as already upstream. What remains is small and not about lint.

## What is still unique to this branch

- Two characterisation tests: `TodosController::Page` (`last?`, `before_last?`, `next_param`) and `PackingSlip::Line#paid_amount`. #406 moved these methods out of Struct blocks without a covering test. Needed: the playbook says every code change has tests.
- A reason comment above `**untyped` on `Assistant::ChargeToAppropriation.call` (already on the branch). Needed: the `untyped` rule asks for a reason. The same gap exists on `Importing::ING::Row#initialize` (`**untyped`) and `Assistant::ImportAlbertHeijnMail.describe` (`untyped basket`) on `main`.
- A correction to the `Todo::Item` YARD block: `date` is `ActiveSupport::TimeWithZone, nil` (already on the branch), and `record` omits `Product`. Needed: the block contradicts the attribute types in the code.
- The `rubocop-eirvandelden` bump to `d91402e`, which exempts `db/data`, `db/cable_migrate` and `db/queue_migrate` from the signature cop. Not needed: lint is green without it. It only spares future run-once scripts a `#: () -> void` line.

## Proposed outcome

The two characterisation tests exist and pass. The three `untyped` places carry a one-line reason. The `Todo::Item` YARD block matches its attribute types. `bundle exec rubocop` stays at `0 offenses`.

## Constraints

- No linter disable comments, no `.rubocop.yml` edit, no new dependency, no `Gemfile.lock` change.
- Runtime behaviour does not change.
- The pull request carries only these changes. No signature work: `main` has it.

## In scope

- `test/controllers/todos_controller_page_test.rb` and one test in `test/models/importing/albert_heijn/packing_slip_test.rb` (both already on the branch).
- Reason comments on the three `untyped` signatures named above.
- The `Todo::Item` YARD correction.
- Dropping the `rubocop-eirvandelden` bump commit (`26a1ac70`) from the branch.

## Out of scope

- The gem bump. The gem change is on its `main` (`d91402e`); bump it in a later change when a new run-once script needs it.
- Everything #406 already did.

## Acceptance criteria

- `bin/rails test test/controllers/todos_controller_page_test.rb test/models/importing/albert_heijn/packing_slip_test.rb` is green.
- `bundle exec rubocop` reports `0 offenses`; `git diff origin/main -- Gemfile.lock` is empty.
- Each of the three `untyped` signatures has a reason comment directly above it.
- `bundle exec bundler-audit check`, Brakeman and `bin/rails test` stay green.

## Decisions

- Rescope instead of closing the branch: the tests and reason comments still have value, and they are small. (Coordinator, 2026-11-07.)
- Drop the gem bump: lint is green without it, and it needs an approved `bundle update`. Recommended; Etienne may keep it instead.
- Keep `untyped` with reason comments, not real types — the real types fail `Layout/LineLength` (140 to 257 characters) and `#|` continuation fails `Style/RbsInline/InvalidTypes`, so they need a lint exemption. (Etienne, 2026-11-11.)
- The `Todo::Item` YARD fix also corrects `kind`: `todo.rb` builds `:product` items too. (Coordinator, 2026-11-11.)

## Open questions

None.
