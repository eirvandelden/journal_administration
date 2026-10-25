# Review: Group appropriations by person

## Round 1 — 2026-10-25T12:49Z — f0575aa

Checks: `bin/rails test` 1346 runs, 0 failures; `test/system/responsive_tables_test.rb` green; RuboCop, herb-lint and Brakeman clean.

Compliance: criterion 1 → `appropriation_charges_test.rb` "the picker groups this year's appropriations per person, labelled by purpose and year"; criterion 2 → "the picker leaves out appropriations of other years"; criterion 3 → "the picker keeps a payment's appropriation from another year selected in its person's group"; criterion 4 → `appropriations_test.rb` "the year page shows one section per person and one grand total". Every test in `plan.md`'s Proof list exists. No test was weakened: the by-year helper test is replaced as the plan says, and `assert_appropriation_row` now also asserts the person's section exists.

Design: every public method in the diff is signed in `### Signatures` and carries an inline RBS signature. No Law of Demeter chain, no new N+1, no glossary `Avoid:` word.

- [ ] Nit: The person heading hardcodes `colspan="4"`, so it drifts from the header row when a column is added to `labels`; derive it from `labels.size` — `app/views/appropriations/index.html.erb:29` → fixed (Derive the person heading colspan from the column count)

## Round 2 — 2026-10-25T12:53Z — 1936dfb

Checks: `bin/rails test` 1347 runs, 0 failures; RuboCop, herb-lint (no failing offense; the one hint, `label` shadowing a helper at `index.html.erb:21`, is on an unchanged line) and Brakeman clean.

Round 1's nit holds: the heading's `colspan` comes from `labels.size`, and `appropriations_test.rb` "each person heading spans every column of the table" proves it.

Compliance: unchanged from round 1; every criterion still maps to its test and every Proof test exists. No test was weakened.

Design: `reading_order` is a private class method, so it needs no entry in `### Signatures`; it carries an inline RBS signature. No Law of Demeter chain, no N+1, no glossary `Avoid:` word.

Nothing found.
