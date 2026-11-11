# Delivery account: add-inline-signatures

Delivered 2026-11-11. Type: chore. Delivery: autonomous. Codex review: no.

## Behaviour delivered

PR #406 on `main` already turned `ci / lint` green with inline RBS signatures, so this branch was rescoped (intent accepted 2026-11-11). It now adds only what `main` lacks:

- Two characterisation tests for code #406 moved out of Struct blocks: `TodosController::Page` (`last?`, `before_last?`, `next_param`) and `Importing::AlbertHeijn::PackingSlip::Line#paid_amount`.
- A one-line reason comment above each of the three `untyped` signatures: `Importing::ING::Row#initialize`, `Assistant::ImportAlbertHeijnMail.describe` and `Assistant::ChargeToAppropriation.call`.
- The `Todo::Item` YARD block now matches its attribute types: `kind` includes `:product`, `date` is `ActiveSupport::TimeWithZone, nil`, `record` includes `Product`.

No runtime behaviour changes. No `Gemfile.lock` change: the `rubocop-eirvandelden` bump commit was dropped (intent Decision).

## Evidence

- Real types were tried and rejected on evidence (2026-11-11): `Layout/LineLength` flags the three full signatures at 140, 178 and 257 characters (`AllowQualifiedName` only spares a line whose overflow is a qualified name), and a `#|` continuation fails `Style/RbsInline/InvalidTypes`. Etienne chose to keep `untyped` with reason comments.
- `grep -B1 '#:.*untyped'` on the three files shows the reason line directly above each `#:` line.
- `git diff origin/main --stat` lists only `app/models/importing/ing/row.rb`, `app/models/todo.rb`, `app/tools/assistant/charge_to_appropriation.rb`, `app/tools/assistant/import_albert_heijn_mail.rb`, the two test files and the change folder.

## Check results (at 8e47e064, rebased on origin/main 9570868e)

- `bin/rails test test/controllers/todos_controller_page_test.rb test/models/importing/albert_heijn/packing_slip_test.rb`: 27 runs, 0 failures.
- `bin/rails test`: 1635 runs, 4872 assertions, 0 failures, 0 errors, 0 skips.
- `bundle exec rubocop`: 468 files, no offenses.
- `bundle exec bundler-audit check`: no vulnerabilities.
- `bundle exec brakeman --no-pager -q`: 0 security warnings.
- `git diff origin/main -- Gemfile.lock`: empty.
- lefthook pre-push passed on the `--force-with-lease` push.

## Review outcome

- Plan critique (Codex, one round): five findings, four fixed, one dismissed (push before review: the implement stage pushes a work-in-progress branch; review runs before `deliver`).
- Claude reviewer: rounds 1 and 2 (original scope) closed; round 3 at 8e47e064 found nothing. `deliver --check` exits 0.

## Follow-ups (not in this change)

- `app/models/importing/ing/row.rb` on `main` still has unexplained `untyped` on its `attr_reader` line and on `parse_amount`.
- `commit-review` took its commit subject from round 1's first finding ("docs: review findings for The `**String` shortcut on") instead of the latest round.
- GitHub reports one moderate Dependabot alert on `main` (#249), unrelated to this change; local `bundler-audit` is clean.
