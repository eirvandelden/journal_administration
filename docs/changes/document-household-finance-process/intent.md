# Intent: Document how the household does its finances

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

The way the household runs its money is written down nowhere in the repository. The knowledge of the "potjes" (virtual accounts), how salary is split over them and how purchases are tracked lives only in Etienne's head. A future agent cannot take that working method into account when it categorizes transactions, suggests budgets or analyses spending. The household also feels that spending has outgrown the current budgets, that saving for large goals is not working, and that some potjes are unused. An analysis agent cannot judge those problems without knowing the method they are measured against.

## Proposed outcome

One document in the repository describes the household's finance method in plain terms, and `AGENTS.md` points to it. The document pairs each Dutch term the household uses with the standard financial term, because Etienne is not a financial expert. A later, separate agent can read it and analyse the current finances against it.

## Affected users and systems

- Future agents that read `AGENTS.md`, including the planned finance-analysis agent.
- Etienne and his wife, who confirm the document is true.
- Documentation only: no application code, data or budgets change.

## Constraints

- Etienne describes the method in chat. The document holds only what he confirms; nothing is invented.
- Standard terms are supplied by the agent and flagged as such, so Etienne can correct them.
- The document holds the method only: no euro figures. Current values live in the app, and the document says so.
- ING's names come from public ING web pages only. The agent never logs in to ING and never handles credentials.
- The budget spreadsheet (`Potjes-Tabel 1.csv`, last updated July 2026) is input for the method. It stays outside the repository and is never committed.
- Markdown prose follows playbook rule 26 (one line per paragraph and list item).

## In scope

- How the household's bank accounts are organised: three debit accounts (Samen plus one personal account each), and the potjes on each.
- The ten potjes of the Samen account, their purpose, and which one is unused.
- Etienne's personal potjes. His wife's potjes are not known and are recorded as such.
- The salary routine: each salary arrives in Samen, fill each potje, move the leftover to Buffer.
- The monthly personal transfer: an agreed amount, equal for both, from Samen to each personal account.
- The spending routine: pull money from a potje shortly before or after paying.
- The meaning of Buffer and Reserveringen, with examples.
- A Dutch-to-standard term mapping.
- The document at `docs/household-finances.md`, and a one-line link to it from `AGENTS.md`.
- A new `GLOSSARY.md` seeded with eight agreed finance terms: Appropriation, Betaalrekening, Buffer, Oranje Spaarrekening, Potje, Reserveringen, Samen and Vaste lasten. It is committed on its own.

## Out of scope

- Analysing the current finances; that is a separate agent after this change.
- Changing budgets, closing or renaming potjes, or deciding what to do about the unused one.
- Backfilling the glossary with the app's existing domain terms, such as Transaction and Account.
- Application changes, such as modelling potjes in the app.
- Recording the known problems in the document; Etienne passes them to the analysis agent when the analysis starts.
- Filling the app's budgets from the spreadsheet through the MCP tools; that is a separate change with its own intent.

## Acceptance criteria

- A reader of `AGENTS.md` finds a link to `docs/household-finances.md`.
- The document uses ING's own names for the potjes and the accounts, each with the URL of the public ING page it comes from. A name the agent cannot find on a public page is marked as not confirmed.
- The document says that each salary arrives in the Samen account, fills the Samen potjes, and that the leftover goes to Buffer.
- The document says that each month an equal, agreed amount moves from Samen to each personal account.
- The document lists Etienne's active personal potjes ("Etienne's verzorging", "Steam Deck", "Etienne's Buffer") and says his wife's are not recorded.
- The document says that potje names change over time ("Steam Deck" was renamed several times), so the account number identifies a potje.
- The document says the bank accounts and potjes are debit accounts, and that the household also has a credit card that pays some monthly subscriptions.
- The document says most fixed costs (Vaste Lasten, Verzekeringen, Abonnementen, Heffingen) leave the Betaalrekening directly, and that costs saved up ahead go through "Reserveringen" instead.
- The document says the bank is ING and that the potjes sit under the "Oranje Spaarrekening", next to a Betaalrekening.
- The document says every move into or out of a potje appears in the bank export, and that import detects it and sets the category to Transfer, which budgets exclude.
- The document says the app holds the Oranje Spaarrekening as one Samen account, so only a transaction's note holds the potje's code.
- The document lists all ten Samen potjes and marks "Cosimo" as currently unused.
- The document says that a purchase is pulled from a potje shortly before or after it is paid, so what is left stays visible.
- The document says that Reserveringen holds money saved ahead for recurring costs, with the animal insurance, the trimsalon and the dentist as examples.
- The document says what Buffer holds: the salary leftover and anything that cannot come from a potje. It serves as both surplus and emergency fund, and no target size is recorded.
- The document says that most appropriations are saved for in "Cadeautjes en speelgoed" or in "Reserveringen", and that the app's appropriation is the matching record.
- The document says that these two potjes are not funded enough, so Christmas and Sinterklaas are paid from "Kinderen kleding".
- Each Dutch term in the document has its standard financial term next to it.
- The document contains no euro amounts and points to the app for current values.
- `GLOSSARY.md` lists the eight agreed terms in alphabetical order, one bullet each, and the finance document uses them.

## Decisions

- No GitHub issue; the slug is `document-household-finance-process` — no reason given.
- Etienne explains the method in chat; the agent does not draft from the code first — his choice when asked.
- The bank is ING, and the potjes are part of a Spaarrekening — Etienne's words; the app side was read from the dev database, read-only.
- Buffer is both the salary leftover and the emergency fund — Etienne's answer; he gave no target size.
- Appropriations are saved for in "Cadeautjes en speelgoed" or "Reserveringen" — Etienne chose option A; those potjes are underfunded, so Christmas and Sinterklaas come from "Kinderen kleding".
- The document lives at `docs/household-finances.md`, linked from `AGENTS.md` — recommended option chosen; `docs/` holds the other documents and agents read `AGENTS.md` first.
- The document holds the method only, with no amounts — "actual values should be in the app itself".
- Most fixed costs go directly from the Betaalrekening, and the household has a credit card for some monthly subscriptions — Etienne's answer; the exceptions are not listed.
- The planning agent looks up the names ING uses on the ING website so the document matches them — Etienne's request; limited to public pages by the agent's own rule, since a login would need his credentials.
- The change starts the repository glossary with the eight finance terms — Etienne: "this change does also make a great starting point for starting a glossary.md".
- Codex does not review — Etienne's answer, "no codex".
- Delivery is autonomous — Etienne's choice, no reason given.
- The document does not record the known problems — Etienne: "we don't need to save the known problems, we can pass that along to a new agent when analysis starts".
- Document first, analyse afterwards with a new agent — the analysis needs the method as its baseline.
- The document uses standard financial terms next to the Dutch ones — Etienne is not a financial expert and relies on the agent for terms and methodology.

## Open questions

None.
