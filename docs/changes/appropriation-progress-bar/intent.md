# Intent: Show a progress bar per appropriation

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

The appropriations list shows an appropriation as separate figures: amount, charged and left over. To see how much of a potje is used, Etienne reads and compares numbers across columns.

## Proposed outcome

Each appropriation shows a progress bar of what is charged against what was appropriated. The amount stands on its left and what is left over stands on its right.

## Affected users and systems

The household members who use the appropriations list and the appropriation show page. The views `app/views/appropriations/index.html.erb` and `show.html.erb`. `Appropriation#amount`, `#charged`, `#balance` and `#overspent?` already hold the figures. No schema or route change is expected.

## Constraints

Follow the existing stacked responsive table and the mvpa.css styling. Strings go through i18n. The repository has no progress bar or meter yet. The bar must stay readable in the stacked layout on a narrow screen.

## In scope

- A progress bar on each row of the appropriations list, between the Amount and the Left over columns.
- The Charged column leaves the list; the bar stands in its place.
- A bar in the total row at the foot of the list, for all charged against all appropriated.
- A progress bar on the appropriation show page, above the existing Amount, Charged and Balance figures.
- An overspent appropriation shows a full bar with the same overspent mark as its balance.

## Out of scope

- Changes to how an appropriation is charged, or to `Appropriation#charged` and `#balance`.
- Other pages that show appropriations.
- A bar that draws the overspent part past the full length.

## Acceptance criteria

- The list shows Purpose, Amount, a bar and Left over for each appropriation, and no Charged column.
- An appropriation of €100 with €25 charged shows a bar a quarter full, €100 on its left and €75 on its right.
- An appropriation with nothing charged shows an empty bar.
- An appropriation of €100 with €130 charged shows a full bar marked as overspent, and a left over of -€30 marked as it is today.
- The total row shows a bar for the sums of all rows above it.
- The show page shows the same bar above its Amount, Charged and Balance figures.

## Decisions

- The bar goes on the list and on the show page — "each appropriation" covers both pages.
- The list shows the bar between Amount and Left over and drops the Charged column — matches the wording "total on the left and left over on the right"; no reason given beyond that.
- An overspent appropriation shows a full bar marked as overspent — matches the existing mark on the balance; no reason given beyond that.
- The total row gets a bar — the total row then matches the rows above it.
- On the show page the bar sits above the figures — no information is removed.

## Open questions

None.
