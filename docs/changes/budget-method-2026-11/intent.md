# Intent: Document the household budget method from 2026-11

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no.

## Problem

`docs/household-finances.md` and `GLOSSARY.md` describe the budget method from before 2026-10-22. Agents use them as the baseline when they categorize transactions, suggest budgets or analyse spending. Today they read a method that no longer holds: the salary leftover goes to Buffer, child benefits are not mentioned, Cosimo is an unused potje, Christmas is paid from Kinderen kleding, and Buffer is both surplus and emergency fund.

## Proposed outcome

The document and the glossary describe the method Etienne accepted on 2026-10-22, which the app (handoff A) and the bank (handoff B) already follow. An agent that reads them books, budgets and analyses by the new method. The document still holds the method only: no amounts, no account numbers, no potje codes.

## Affected users and systems

- Agents that categorize transactions, suggest budgets or analyse spending, through the MCP or in this repository.
- Etienne and his partner, as readers.
- No code, no app data, no bank settings.

## Constraints

- Method only: no amounts, no account numbers, no potje codes, no category ids. Amounts stay in the app and in `.git/herdr/budget-proposal.md`.
- The document may state these facts: KGB arrives monthly, kinderbijslag quarterly; Etienne's partner has no income; the study loan ends around late 2031.
- Days of the month that are part of a rule may appear (KGB around the 20th, the leftover move on the 21st).
- The methods section names "envelope budgeting" as the method. A potje is still called a potje, never an envelope, as the glossary's `Avoid:` list says.
- Agent-chosen standard terms stay marked "agent-supplied".
- One line per paragraph in markdown prose (playbook rule 26).
- Permissions: none needed. No gems or packages, no system tools, no migrations, no deploy files.

## In scope

`docs/household-finances.md`:

- Income: household income is the salary only, from one earner. Child benefits (KGB monthly, kinderbijslag quarterly) go to `Kinderen` and pay only for the children: clothing, furniture, hobbies, gifts, toys and parties, care and school, and their savings. Kinderen keeps about one quarter of kinderbijslag, because it arrives per quarter.
- The Samen potjes table: ten potjes with their current names, standard terms, purposes and status. No former names. `Kinderen`, `Boodschappen en huishouden`, `Auto en vervoer`, `Reserveringen`, `Vrije tijd en hobby`, `Cadeautjes` (adult and family gifts only), `Huis` (home maintenance and furnishing; children's rooms go to Kinderen), `Vakantie`, `Projecten` (in use), `Buffer`.
- Windfalls: the 13e maand pays Huis, the rest goes to Buffer. The vakantiegeld pays Vakantie, the rest goes to Buffer. Tax refunds go to Projecten. Gifts are extra and go to Projecten or the children.
- Buffer: emergencies only, never a known cost. Target about three months of essential costs. Above the target, its share of the windfalls goes to Projecten.
- Onvoorzien (unplanned costs): not a potje, but a small amount that stays on the Samen Betaalrekening after the monthly transfers. An unplanned cost is paid from it. When a potje runs empty, the Betaalrekening pays the rest, and that potje pays it back after the next salary-day transfers. On the 21st, just before the salary, the leftover minus the KGB that arrived on the 20th moves to Projecten.
- Reserveringen: keep the examples and add the yearly energy peak in April.
- Personal allowance: an equal monthly amount to each partner. Personal purchases go on the personal accounts; no paying from Samen and paying back.
- Fixed costs: the credit card bill is booked as a transfer linked to its purchases, not as a cost.
- Appropriations: children's appropriations are saved for in Kinderen; the rest in Cadeautjes or Reserveringen. The Christmas-from-Kinderen-kleding workaround goes.
- App categories, by name: a `Kinderen` parent category for the children's spending; Studieschuld under Vaste lasten; `Kindgebonden budget` under Inkomsten, where every KGB payment is booked.
- A methods section naming each method with its standard term: envelope budgeting, zero-based budgeting, sinking fund, pay yourself first, emergency fund.
- The `Words we use` table gets Onvoorzien, Kinderen, Huis, Kindgebonden budget, Kinderbijslag, 13e maand and Vakantiegeld.
- The flowchart and every other section the new method contradicts (Salary routine, Buffer and Reserveringen, Spending routine where needed).
- The study loan end (around late 2031) as the moment savings can rise.

`GLOSSARY.md`:

- Rewrite `Buffer`: the emergency fund, emergencies only, filled from windfall leftovers.
- Add `Kinderen`, `Onvoorzien` and `Projecten`.

## Out of scope

- Any amount, account number, potje code or category id.
- Former potje names (git history holds them).
- Changes in the app or at the bank (handoffs A and B), including the open A6 linking of credit card bills.
- The "How the app sees this" import description, except where a new category needs a line.

## Acceptance criteria

- An agent that reads the document books a KGB payment under Inkomsten - Kindgebonden budget, and does not count it as household income.
- The document says the Betaalrekening leftover moves to Projecten on the 21st; nothing says the salary leftover goes to Buffer.
- The document and the glossary both say Buffer pays emergencies only, with a target of about three months of essential costs, and that above the target its share goes to Projecten.
- A reader can tell where each windfall goes: 13e maand to Huis then Buffer, vakantiegeld to Vakantie then Buffer, tax refunds to Projecten, gifts to Projecten or the children.
- The potje table lists exactly ten potjes, all active, under their current names; Cosimo and Kinderen kleding appear nowhere.
- A children's birthday party is paid from Kinderen; a gift for an aunt is paid from Cadeautjes.
- When the Boodschappen en huishouden potje is empty, the document tells the reader to pay from the Betaalrekening and to move the amount back from that potje after the next salary-day transfers.
- The document says Onvoorzien is not a potje.
- The document says personal purchases go on the personal accounts.
- The document says a credit card bill is a transfer linked to its purchases.
- The app categories part names Kinderen, Studieschuld under Vaste lasten and Kindgebonden budget, without ids.
- The methods section names the five methods with their standard terms.
- The `Words we use` table has rows for Onvoorzien, Kinderen, Huis, Kindgebonden budget, Kinderbijslag, 13e maand and Vakantiegeld.
- `GLOSSARY.md` has entries for Kinderen, Onvoorzien and Projecten, keeps alphabetical order, and Buffer no longer mentions the salary leftover.
- The flowchart shows one salary, child benefits flowing to Kinderen, the windfalls, and the leftover moving to Projecten.
- The document contains no euro amount, no account number, no potje code and no category id.

## Decisions

- Words table gets Onvoorzien, Kinderen, Huis and the income words (Kindgebonden budget, Kinderbijslag, 13e maand, Vakantiegeld) — every Dutch term the new method introduces gets a standard term.
- Glossary: Buffer becomes "emergencies only"; add Kinderen, Onvoorzien and Projecten — the old Buffer entry contradicts the method, and the three new potje roles are agreed terms.
- Potje renames: current names only, no former-name column or rename note — git history is enough.
- Huis pays for maintenance and furnishing — children's rooms stay with Kinderen.
- Appropriations split by recipient: children's in Kinderen, the rest in Cadeautjes or Reserveringen — follows the rule that child benefits pay only for the children.
- App categories by name only, no ids — matches "for current values, use the app"; ids can differ between databases.
- Document the credit card bill as a transfer linked to its purchases — it is part of the accepted method, even though the web linking (A6) is still open.
- Autonomous delivery, no Codex review — chosen by Etienne.

## Open questions

None.
