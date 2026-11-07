## Round 1 — 2026-11-07T09:06Z — 6a21ed7b

Compliance: every acceptance criterion and every Proof test exists in `test/integration/appropriation_progress_test.rb`; no existing test was weakened, skipped or deleted. The `assert_appropriation_row` helper keeps its signature. Design: no new public Ruby method, no Demeter chain, no N+1 (slope test proves 4 queries per appropriation), no glossary term from an Avoid list.

- [ ] Nit: The show page bar sits directly on the figures with no spacing; add a bottom margin for the bar inside `article` — `app/assets/stylesheets/local/modules/appropriations.css:1` → fixed (fix: space the show page bar, shorten the caption line, hoist the totals)
- [ ] Nit: Line 2 of the partial is about 150 characters, over the ~120 limit; split the `t(...)` call over lines or move the caption into a local — `app/views/appropriations/_progress.html.erb:2` → fixed (fix: space the show page bar, shorten the caption line, hoist the totals)
- [ ] Nit: The `total_amount` and `total_charged` assignments sit between the last `tbody` and the `tfoot`; move them next to `labels` above the table — `app/views/appropriations/index.html.erb:41` → fixed (fix: space the show page bar, shorten the caption line, hoist the totals)

## Round 2 — 2026-11-07T09:08Z — 5f1c2621

Round 1 fixes checked: the show page bar is a direct child of `article`, so `article > :is(progress, mark:has(> progress))` spaces it and leaves the table bars alone; the caption call is split under 120 characters; the totals sit above the `article`, so the empty case still sums an empty list. The fix commit adds no regression.

Nothing found.
