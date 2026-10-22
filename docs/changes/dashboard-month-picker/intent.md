# Intent: Pick whole months on the dashboard

Author: Etienne van Delden de la Haije. Status: accepted. Type: feature. Delivery: autonomous. Codex review: no.

## Problem

The dashboard asks for an exact start day and end day. Nobody ever needs a specific day: every period is a whole month, several months or a year. The day fields also hide a bug. The budget goal for a category is the stored monthly amount times days / 30. A 31-day month gives 1.529,33 for Vaste lasten when the stored amount is 1.480,00. February undershoots and a whole year gives 12,17 months.

## Proposed outcome

The dashboard shows months and years, never days. The period always runs from the first day of the first month to the last day of the last month. The budget goal counts whole months, so a full month shows exactly the stored monthly amount.

## Affected users and systems

Household members who read the dashboard. The dashboard page, its date filter form and Stimulus controller, `Dashboard`, `DateRange`, the budget-vs-actual chart and the nl/en locale files.

## Constraints

- No gems, packages, migrations or deploy files are needed. No other permissions are requested.
- Locale files stay normalized (`i18n-tasks normalize`).
- The MCP `budget_status` tool uses the dashboard dates too. Its code stays as is; only the goal it reports changes (see In scope). The budget pages stay untouched.

## In scope

- Replace the start and end day fields with a "from" month field and a "to" month field.
- Keep the quick filter: current month, last month, three months, this year, last year.
- "This year" runs from January through the current month.
- The budget goal is the stored monthly amount times the number of months in the period.
- A missing, unreadable or reversed month selection falls back to the current month.
- Old links with exact days (`start_date`, `end_date`) stop working and fall back to the current month.
- Show the selected period as months or years in the dashboard, never as days.
- The MCP `budget_status` tool reports the same goal: a span that is whole calendar months scales by months, not days / 30.

## Out of scope

- Any change to how budgets are stored, created or closed.
- Daily or weekly views.
- The historical-average line, beyond using whole-month periods.
- Other pages that show dates.

## Acceptance criteria

- Selecting October 2026 shows the Vaste lasten goal as the stored monthly amount, 1.480,00 when that is the stored amount, not 1.529,33.
- Selecting February 2026 shows the same goal as October 2026.
- Selecting January to March 2026 shows three times the monthly amount.
- Selecting the quick filter "this year" in October shows ten times the monthly amount and counts spending from 1 January to 31 October.
- Selecting "last year" shows twelve times the monthly amount.
- The dashboard shows no field or label with a day of the month.
- Choosing a "to" month before the "from" month shows the current month.
- Opening `/dashboard?start_date=2026-10-15&end_date=2026-10-20` shows the current month.
- Asking the MCP `budget_status` tool for 1 to 31 October 2026 reports the stored monthly amount, not 1.529,33.

## Flagged concerns

The scope choice was "month/year pickers only". With the old days / 30 maths a whole month would still show 1.529,33, so the original symptom would stay. Chosen side: months are the unit everywhere, so the goal counts months, not days. The 1.480,00 example above is the proof.

## Decisions

- Only the month/year pickers, no separate scaling intent — "the dashboard shouldn't show days, it should show months and/or years".
- Two month fields plus the quick filter — recommended option accepted, no reason given.
- "This year" runs January through the current month — recommended option accepted, no reason given.
- Old day-based URLs stop working — chosen over snapping them to whole months, no reason given.
- Autonomous delivery, no Codex review — recommended options accepted, no reason given.
- The MCP tool also counts whole months (added after the plan stage, 2026-10-22) — recommended option accepted, no reason given; it corrects the first draft's wrong claim that MCP does not use the dashboard dates.
- Write the plan's glossary terms into a new `GLOSSARY.md` — recommended option accepted, no reason given.

## Open questions

None.
