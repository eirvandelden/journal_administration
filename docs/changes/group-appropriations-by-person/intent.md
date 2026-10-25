# Intent: Group appropriations by person

Author: Etienne van Delden de la Haije. Status: accepted. Type: feature.
Delivery: autonomous. Codex review: no.

## Problem

The appropriation picker on a transaction or split lists every appropriation of every year, grouped by budget year, each labelled "Purpose Recipient Year" (for example "Sinterklaas Serena 2026"). The recipient sits in the middle of the label, so finding the right appropriation for a person is slow. The appropriation index is one flat table, so one person's appropriations are scattered.

## Proposed outcome

The picker shows one group per person, and each option reads "Purpose Year". The index shows one section per person.

## Affected users and systems

- Household members who assign a transaction or split to an appropriation (`appropriations/_charge_form`).
- Household members who read the appropriation index.
- `AppropriationsHelper#grouped_appropriation_options` and `AppropriationsController#index`.

## Constraints

- `Appropriation#to_s` stays unchanged; the show page and other callers use it.
- No new dependencies, migrations or deploy changes.

## In scope

- Picker: only appropriations of the current year, grouped per person sorted by name, options labelled "Purpose Year", purposes A to Z inside a group.
- Picker: the appropriation already chosen for the payment or split stays listed, in its person's group, even when it is from another year.
- Index: the table for the chosen year gets one section per person, sorted by name, purposes A to Z inside a section. The Recipient column goes. The grand total row stays.

## Out of scope

- Per-person subtotals on the index.
- Changing `Appropriation#to_s`, the show page, the assistant (MCP) tools or the year navigation.

## Acceptance criteria

- With Serena and Chiara each holding "Sinterklaas 2026" and "Kerst 2026", the picker shows the group "Serena" with "Kerst 2026" and "Sinterklaas 2026", then the group "Chiara" with the same two options. Groups sort by person name, so Chiara comes first.
- An appropriation of 2025 does not appear in the picker.
- A payment already charged to a 2025 appropriation still shows that appropriation selected, in its person's group.
- The index for 2026 shows a heading per person with that person's appropriations under it, and one grand total.

## Decisions

- Picker shows only the current year — only the current year is needed to pick the right appropriation.
- Per-person grouping on the index, without subtotals — "per person is enough for now".
- Keep the currently selected appropriation listed — default stated by Claude and agreed with "agreed".

## Open questions

None.
