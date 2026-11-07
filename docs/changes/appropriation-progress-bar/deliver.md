# Delivery: appropriation-progress-bar

## Behaviour delivered

The appropriations list shows Purpose, Amount, a progress bar headed "Used" and Left. The Charged column is gone. The total row at the foot has a bar for the sums of all rows. The appropriation show page has the same bar above its Amount, Charged and Balance figures.

An overspent appropriation shows a full red bar with the same overspent mark as its balance. A refund surplus shows an empty bar. The bar's accessible name states the real charged figure and the amount.

The change adds one partial, one small stylesheet and three locale keys. No model, controller, route or schema changed.

## Evidence

- A new integration test file holds one test per acceptance criterion: the column set, a quarter-full bar, an empty bar, an overspent bar, a refund surplus, the total row, the show page, and a query slope of four queries per appropriation.
- Each new test failed before the code and passed after it.
- Screenshots from a throwaway system test showed the wide list, the phone width with stacked rows, and an overspent show page. The bar sits between Amount and Left, keeps full width in the stacked layout, and turns red when overspent. A second screenshot confirmed the spacing fix on the show page. The throwaway test was deleted.
- The dark theme was not looked at.

## Check results

- `bin/rails test`: 1527 runs, 0 failures. After the review fixes, 71 targeted runs passed.
- `bin/rails test:system`: 32 runs, 0 failures.
- Rubocop, Brakeman and Bundler Audit: clean, run directly. `i18n-tasks normalize`: no diff.
- Herb: 0 failing offenses and one old hint on a loop in `index.html.erb` that this change did not add.
- The Bundler hooks (rubocop, brakeman, bundler_audit, tests) fail inside git hooks because of a `GIT_DIR` problem with git-sourced gems in worktrees. Etienne approved skipping them for this branch's commits and pushes. Herb still ran.

## Review outcome

Round 1 found three Nits: spacing on the show page, one long line in the partial, and the totals placed between table sections. All three were fixed in one commit. Round 2 found nothing. Codex review was not enabled.
