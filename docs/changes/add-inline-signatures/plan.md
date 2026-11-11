# Plan: Add inline RBS signatures (rescoped)

From `intent.md` (rescoped 2026-11-07, accepted 2026-11-11). Status: accepted.

## Design

### Domain terms

No new term. **Basket**: one of the three Albert Heijn readers `Importing::AlbertHeijn::BasketMail.parse` returns (`PackingSlip`, `OlderPackingSlip`, `OrderConfirmation`), as `app/models/receipt/recordable.rb` already words it. Prose says "delivery", never "order".

### Diagrams

Not affected: comments, YARD text and two tests. No class, table, message flow or state changes. `main` already reopened `TodosController::Page` and `PackingSlip::Line`.

### Signatures

No signature changes. Three `untyped` signatures keep their type and gain, or keep, a one-line reason comment directly above the `#:` line. The `#:` line stays the last comment line above `def`.

- `Importing::ING::Row#initialize` (`app/models/importing/ing/row.rb`): add `# The splat stands for the nine other CSV columns; naming them runs past 120 characters.` (no type claim: CSV gives `nil` for an unquoted empty field) above `#: (date: DateTime, amount: Integer, **untyped) -> void`.
- `Assistant::ImportAlbertHeijnMail.describe` (`app/tools/assistant/import_albert_heijn_mail.rb`): add ``# The basket is any reader `BasketMail.parse` returns; their union runs past 120 characters.`` above `#: (Receipt receipt, untyped basket) -> MCP::Tool::Response`.
- `Assistant::ChargeToAppropriation.call` (`app/tools/assistant/charge_to_appropriation.rb`): keeps its existing reason comment (on the branch).

`Todo::Item` YARD block (`app/models/todo.rb`), to match the Struct attribute types:

- `kind`: `@return [Symbol] :transaction, :account or :product`.
- `date`: `@return [ActiveSupport::TimeWithZone, nil] Sort date for the item` (on the branch).
- `record`: `@return [Transaction, Account, Product] The underlying AR record`.

Not checked: this project declined Steep and rbs_rails. `Style/RbsInline/InvalidTypes` checks RBS syntax only.

### Complexity

Not affected: no runtime path changes and no queries.

### Invariants

- Every `untyped` touched by this branch has a reason comment directly above its `#:` line. Enforced by review; proven by the grep in Proof.
- `#:` stays the last comment line directly above `def`. A house rule, not enforced by a cop (a comment between them passes the cops); proven by the `grep -B1` check in Proof and by review.
- The pull request changes no `Gemfile.lock`. Proven by `git diff origin/main -- Gemfile.lock`.

### Alternatives

1. **Reason comments, `untyped` kept (chosen).** Smallest diff, matches the house precedent in `Receipt::Recordable`, needs no lint change.
2. **Real types.** Rejected: verified on 2026-11-11 that `Layout/LineLength` flags all three (140, 178 and 257 characters; `AllowQualifiedName` only spares a line whose overflow is a qualified name), and a `#|` continuation fails `Style/RbsInline/InvalidTypes`. A lint exemption is out of scope (Etienne, 2026-11-11).
3. **`**String` on `Row#initialize`.** Rejected: signature work, which the intent's Constraints rule out.

## Design decisions

- The gem-bump commit `26a1ac70` is dropped from the branch, not reverted, so the pull request holds no `Gemfile.lock` change (intent Decision).
- The branch is rebased onto the current `origin/main`: `main` moved after the 2026-11-07 rebase (#409, #410), and the diff against `main` must show only this change.
- The `kind` YARD line is corrected with `record`, because the same block contradicts the code (`todo.rb` builds `:product` items; intent Decision 2026-11-11).

## Integration points

None. No gem, config, CI or deploy file changes.

## Files that change

- `test/controllers/todos_controller_page_test.rb` (new, on the branch).
- `test/models/importing/albert_heijn/packing_slip_test.rb`: one test (on the branch).
- `app/tools/assistant/charge_to_appropriation.rb`: reason comment (on the branch).
- `app/models/importing/ing/row.rb`: reason comment above `initialize`.
- `app/tools/assistant/import_albert_heijn_mail.rb`: reason comment above `describe`.
- `app/models/todo.rb`: `date` YARD line (on the branch); `kind` and `record` YARD lines.
- `docs/changes/add-inline-signatures/`: intent, plan and review (removed by `deliver`).

Out of scope: real types for the three signatures, any lint config, the gem bump, everything PR #406 did.

## Order of work

1. Drop `26a1ac70` with `git rebase --onto 26a1ac70^ 26a1ac70`. Then fetch `origin` and rebase onto `origin/main`. Resolve each conflict on its merits, stage the file and continue with `GIT_EDITOR=true git rebase --continue` (the configured editor waits for input). Confirm `git diff origin/main -- Gemfile.lock` is empty and `git diff origin/main --stat` lists only the files above.
2. Run `bin/rails test test/controllers/todos_controller_page_test.rb test/models/importing/albert_heijn/packing_slip_test.rb`: green, since they pin existing behaviour.
3. Add the two reason comments and the `kind` and `record` YARD lines. Run `bundle exec rubocop` on the three files. Commit them as `docs: explain the untyped signatures and fix the Todo::Item YARD`.
4. Run `bundle exec rubocop`, `bundle exec bundler-audit check`, `bundle exec brakeman --no-pager -q` and `bin/rails test`.
5. Push the work-in-progress branch with `--force-with-lease`, the worktree's `bin/` first on `PATH`, through the lefthook hooks. The coordinator then runs `review` before `deliver` opens the pull request.

## Risks

- A reason comment placed between `#:` and `def` passes the cops but breaks the house rule. Mitigation: the `grep -B1` check in Proof after step 3.
- The rebase onto `main` may conflict in `todo.rb` or the tools. Mitigation: resolve each file on its merits; tests and rubocop run after.
- `review.md` is untracked. Mitigation: no step cleans untracked files.

## Proof

- The two characterisation tests are green → `test/controllers/todos_controller_page_test.rb` `the last page knows it is last`, `a page before the last is before last`, `the next page number is one more`; `test/models/importing/albert_heijn/packing_slip_test.rb` `a line's paid amount is its full amount less its bonus`.
- Rubocop reports `0 offenses` and the lockfile is unchanged → check: `bundle exec rubocop`; `git diff origin/main -- Gemfile.lock` is empty.
- Each of the three `untyped` signatures has a reason comment directly above it → check: `grep -B1 '#:.*untyped'` on the three files shows a `#` reason line above each.
- `bundler-audit`, Brakeman and the full suite stay green → check: `bundle exec bundler-audit check`, `bundle exec brakeman --no-pager -q`, `bin/rails test`.
- Invariant: the pull request holds only this change → check: `git diff origin/main --stat` lists only the files in `## Files that change`.

Per changed file, the unit tests expected:

- `app/controllers/todos_controller.rb` (`TodosController::Page`, unchanged code): the three tests above.
- `app/models/importing/albert_heijn/packing_slip.rb` (`PackingSlip::Line`, unchanged code): the one test above.
- `row.rb`, `import_albert_heijn_mail.rb`, `charge_to_appropriation.rb`, `todo.rb`: comments only; existing tests cover them.

Test setup: the new assertions build `TodosController::Page` and `PackingSlip::Line` from plain values, inside the existing setup (`fixtures :all`; `PackingSlipTest` also parses a file fixture).

---
Domain skills applied: rails-testing, ruby-style, dependencies.

## Critique

### Round 1 (codex exec -m gpt-6.1-sol)

- The ING reason comment claims the nine columns are all String, but CSV returns nil for an unquoted empty field → fixed (the comment drops the type claim and keeps the 120-character reason)
- Rubocop does not enforce that `#:` sits directly above `def`; a comment between them passes the cops → fixed (the invariant and the risk now call it a house rule, proven by the `grep -B1` check and review)
- Conflict recovery omits `--continue`, and the configured editor waits for input → fixed (step 1 continues with `GIT_EDITOR=true git rebase --continue`)
- The plan pushes before the required review → dismissed: the implement stage pushes the work-in-progress branch, as the implement skill says; no pull request is open, and the coordinator runs `review` before `deliver` opens one (playbook 7a); step 5 now says so
- "No fixtures" is inaccurate: both test files inherit `fixtures :all` and `PackingSlipTest` parses a file fixture → fixed (Test setup now says plain values inside the existing fixture-backed setup)
