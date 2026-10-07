# Review: appropriations

## Round 1 — 2026-09-30 11:04 UTC — 2e11ace

Base: `origin/fix-json-gem-arity`. No uncommitted changes. Suite green (873 runs, 0 failures); rubocop, herb-lint, brakeman clean; `i18n-tasks normalize` leaves no diff.

Compliance: every acceptance criterion R1–R18 has a matching test in the diff, and every test named in `plan.md` `## Proof` exists (48 unit/integration names plus the receipt and import-job tests). No existing test was weakened, skipped or deleted; the diff only adds lines under `test/`.

Judged, not findings: the two `AppropriationChargesController`s are near-identical, but there are only two, so extracting a shared piece now would come before the rule of three calls for it. Year totals were already in the plan ("year totals for R13").

- [x] Important: The appropriation page crashes if a charged payment has no booking date. `booked_at` can be null (`db/schema.rb:222`, no presence validation, and the transaction form's date field can be left blank). `#charges` then fails in `sort_by(&:booked_at)` with a nil-to-Time comparison, and the view calls `l(charge.booked_at.to_date)` on nil. The existing transaction page already guards this case (`transactions/show.html.erb:54`). No test charges a payment without a booking date — `app/models/appropriation.rb:58`, `app/views/appropriations/show.html.erb:37` → fixed (fix(appropriations): list a charged payment without a booking date)
- [x] Nit: The index page repeats the same queries many times. `#charged` is not memoized and costs four queries. Each row calls it three times: the charged cell, then `overspent?` and `balance` in `_balance`. `total_charged` loads the records again and calls it once more per row, and `total_balance` calls `total_charged` a second time. That comes to about 20 queries per row. The sums are correct; only the repeated work is wasteful — `app/models/appropriation.rb:27` → fixed (perf(appropriations): work out what is charged once per appropriation)
- [x] Nit: `plan.md` "Files that change" was not updated for work added during implementation. Missing are the `Appropriation.named` scope (used by the uniqueness check and `SetAppropriation`), `TransactionSplit` delegating `booked_at` (used by `#charges`), and the partials `appropriations/_balance.html.erb` and `transactions/_appropriation.html.erb`. All four are small and serve planned requirements — `docs/changes/appropriations/plan.md:1` → fixed (docs(appropriations): list what the build added in the plan)
- [x] Nit: The charge select has no blank option. On an uncharged payment the browser preselects the first appropriation of the newest year, so pressing "Charge" without looking charges it there. `required: true` has no effect when no option is blank — `app/views/appropriations/_charge_form.html.erb:4` → dismissed: Rails adds a blank first option to a required select (ActionView `SelectRenderer#placeholder_required?`), so an uncharged payment proposes no appropriation; verified with a request test that passed unchanged
- [x] Nit: `?year=` with an empty or non-numeric value becomes year 0 through `to_i`, which shows "Appropriations 0" and links to years -1 and 1 — `app/controllers/appropriations_controller.rb:11` → fixed (fix(appropriations): a year that is not a number shows this year)

## Round 2 — 2026-09-30 11:25 UTC — 7a7da8d

Base: `origin/fix-json-gem-arity`. No uncommitted changes. Suite green (877 runs, 0 failures); rubocop, herb-lint and brakeman clean; `i18n-tasks normalize` leaves no diff. Since round 1 the diff under `test/` only adds lines; no test was weakened, skipped or deleted.

Round-1 outcomes checked:

- Undated charge (1519a39): holds. `#charges` puts undated charges last instead of comparing nil, the view prints "-", and there is a model test and a request test for it.
- Repeated queries (7a7da8d): holds. `#charged` is worked out once per record. The footer sums the rows already loaded by `each`, so it reuses that result, and the new request test caps split-part queries at two per appropriation. No stale value reaches a page: no code in `app/` reads `charged`, changes a charge, and then reads `charged` again on the same object.
- Year that is not a number (b849d9a): holds for "" and "next", and there is a test for both.
- Blank charge option (947b69a, dismissed): the dismissal is correct. In actionview 8.1.4, `SelectRenderer#select_content_tag` sets `include_blank` when `placeholder_required?` is true (`required`, not `multiple`, size 1). `_charge_form` passes `required: true`, so an uncharged payment has nothing preselected.

- [x] Nit: Carried from round 1, left open by the user: `plan.md` "Files that change" does not list `Appropriation.named`, `TransactionSplit#booked_at` delegation, `appropriations/_balance.html.erb` or `transactions/_appropriation.html.erb` — `docs/changes/appropriations/plan.md:1` → fixed (docs(appropriations): list what the build added in the plan)
- [x] Nit: The `reload` override has no caller and no test. Nothing in `app/` or `test/` calls `reload` on an `Appropriation`, so nothing proves that reloading clears the stored charged amount, and removing the override would leave the suite green. The stored amount is also not cleared when charges are added through the association (for example `appropriation.transactions << payment`). Nothing does that today — `app/models/appropriation.rb:32` → fixed (refactor(appropriations): drop the unused reload override)
- [x] Nit: `Integer(params[:year], exception: false)` reads the year the way Ruby reads number literals, so `?year=02026` becomes octal 1046 and `?year=0x7EA` becomes 2026. You only get these by typing the URL by hand. The previous/next links are built from the parsed year, so they never produce such values — `app/controllers/appropriations_controller.rb:87` → fixed (fix(appropriations): read the chosen year as a plain number)
- [x] Nit: The dismissal of the blank-option finding depends on a request test that was run but not committed. No committed test checks that the charge select on an uncharged payment starts with a blank option, so if `required: true` were dropped, the first appropriation would be preselected again and the suite would stay green — `app/views/appropriations/_charge_form.html.erb:4` → fixed (test(appropriations): an uncharged payment proposes no appropriation)

## Round 3 — 2026-10-01 09:21 UTC — 21abd9c

Base: `origin/fix-json-gem-arity`. No uncommitted changes. Suite green (879 runs, 0 failures); rubocop, herb-lint and brakeman clean; `i18n-tasks normalize` leaves no diff. The diff under `test/` still only adds lines; no test was weakened, skipped or deleted.

Round-2 outcomes checked:

- Reload override (40b4a4a): holds. Nothing in `app/` or `test/` calls `reload` on an `Appropriation`, and the `reload` calls in tests are all on transactions or split parts, followed by `.appropriation`, never by `.charged`. Suite green without the override.
- Year read in base 10 (0d63f04): holds. `Integer(params[:year], 10, exception: false)` still returns nil for a missing year and for array or hash params, so the default to this year is unchanged; "0x7EA" is now refused and "02027" reads as 2027. The new test would have failed before the fix ("02027" in octal is 1047, which has no appropriations).
- Blank-option test (21abd9c): holds. In a throwaway copy of HEAD with `required: true` removed from `_charge_form`, the new test fails on its first assertion (`option[value='']` expected at least 1, found 0). The working tree was not touched.

Nothing new was introduced by the three fixes.

- [x] Nit: Carried from rounds 1 and 2, left open by the user: `plan.md` "Files that change" does not list `Appropriation.named`, `TransactionSplit#booked_at` delegation, `appropriations/_balance.html.erb` or `transactions/_appropriation.html.erb` — `docs/changes/appropriations/plan.md:1` → fixed (docs(appropriations): list what the build added in the plan)

## Round 4 — 2026-10-05 12:27 UTC — 09f204d

Base: `origin/main` (99d59b9). The branch was rebased since round 3: its old base `fix-json-gem-arity` landed on main through the Rails 8.1.4 bump. `git range-diff` shows all 20 branch commits unchanged (`=`); only the base commit dropped out. No uncommitted changes. Suite green (879 runs, 0 failures); rubocop, herb-lint, brakeman and bundler-audit clean; `i18n-tasks normalize` leaves no diff. `db/schema.rb` against main adds only the appropriations table and the two `appropriation_id` columns, at version 2026_09_28_120100.

Bugs: re-read the controllers, models, the `Chargeable` concern and the three assistant tools on the new base. Nothing new. The assistant's `part_of` looks up the remainder too, but `remainder_must_not_be_charged` refuses that charge with a message.

Security: every query goes through bound parameters (`Appropriation.named` included); both charge controllers and the appropriations controller use `params.expect`; a split part is found only among its own payment's explicit parts. Brakeman reports nothing.

Compliance: the diff under `test/` is identical to round 3, so the round-1 mapping of R1–R18 to tests and the `plan.md` Proof list still hold. No test was weakened, skipped or deleted.

- [x] Nit: Carried from rounds 1–3, left open by the user: `plan.md` "Files that change" does not list `Appropriation.named`, `TransactionSplit#booked_at` delegation, `appropriations/_balance.html.erb` or `transactions/_appropriation.html.erb` — `docs/changes/appropriations/plan.md:1` → fixed (docs(appropriations): list what the build added in the plan)

## Round 5 — 2026-10-07 11:12 UTC — 3aea826

Base: `origin/main` (de7eded). The branch was rebased since round 4. `git range-diff` shows the round-4 commits unchanged, except the schema version in the context lines of "Tests for appropriations": main moved from 2026_09_02_090000 to 2026_09_03_151125. `db/schema.rb` against main still adds only the appropriations table and the two `appropriation_id` columns. New since round 4: amendment 1 (`30dcc24`, `e39b1e2`, `3aea826`) and the plan update (`569fedd`). No uncommitted changes. Suite green (887 runs, 0 failures); rubocop, herb-lint, brakeman and bundler-audit clean; `i18n-tasks normalize` leaves no diff; `i18n-tasks missing` finds nothing and no appropriation key is unused.

Bugs: the split-part charge forms sit in their own table cells, and the add-split form follows the table, so no form is nested. Both charge forms target `_top`, so a charge from inside the `transaction_splits` frame loads the full edit page with its flash. The create, update and destroy turbo-stream responses render the new column through `_frame`, and the HTML fallback renders `transactions/edit`. `transactions/_appropriation` has strict locals `(chargeable:)`, and the show page is its only caller.

Security: no new parameters. Both charge controllers only changed their redirect target, which comes from the record found, not from a parameter. The datalist values go through `<%= %>` and are escaped. Brakeman reports nothing.

Compliance:

- R15 show → `a payment's page shows its appropriation, per part when split, without a way to change it`
- R15 whole → `charging an unsplit payment on its edit page makes it count there`
- R15 part → `charging one part on a split payment's edit page counts only that part` (checks only Chiara's row, see below)
- R19 → `the new-appropriation form suggests household members and earlier recipients`
- Every test in the amendment's Proof list exists, including both `.recipient_suggestions` model tests. The R1–R18 mapping from round 1 still holds.
- Changed tests: `a transfer offers no charge` and `an uncharged payment's page proposes no appropriation` now open the edit page instead of the show page. The show page no longer has a form, so the edit page is the place to check; neither test is weaker. The R15 show test kept its assertions and adds two `count: 0` checks. No test was skipped or deleted.

- [ ] Nit: The whole-payment charge section on the edit page is outside the `transaction_splits` frame, so the split turbo streams do not update it. After the first part is added on the page, it still offers to charge the whole payment; the model refuses that on submit with "charge its parts instead". After the last part is removed, it offers no whole-payment charge until the page reloads. No wrong charge can result — `app/views/transactions/edit.html.erb:14` →
- [ ] Nit: No test checks the edit page of a split payment for what it must not offer. Nothing asserts that the whole-payment charge form is absent there, or that the remainder row has no charge form (amendment: "none on the remainder row"). If someone removes `unless @transaction.split?` or adds a form to the remainder row, the suite stays green. The R15 part test also checks only Chiara's row, while the criterion says "each part's row" — `test/integration/appropriation_charges_test.rb:150` →
- [ ] Nit: `recipient_suggestions` sorts case-sensitively, so an earlier lowercase recipient such as "grandma" comes after every capitalised name. When "Grandma" and "grandma" both exist, the spelling that `uniq` keeps depends on the order SQLite returns the rows, because `distinct.pluck` has no order — `app/models/appropriation.rb:23` →
