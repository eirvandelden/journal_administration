# Review: budget-method-2026-11

## Round 1 — 2026-11-06T14:47Z — f0ed9679

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes ran. The change is documentation only, so the Bugs and Security passes found nothing and no test or lint suite applies.

- [ ] Important: The Salary routine says the salary fills "each Samen potje", but the flowchart fills only "Five other potjes" from the salary, and the method fills Kinderen from child benefits and Buffer from windfall leftovers only. An agent that suggests a budget can read either rule and allocate salary to Buffer or Kinderen. Etienne decides which potjes the salary fills (Huis, Vakantie and Projecten are also unclear); then the text, the flowchart edge and "Pay yourself first" (line 125) say the same — `docs/household-finances.md:88` → fixed (docs: align salary routine, child benefit flow and flowchart in household finances)
- [ ] Nit: The flowchart lost the old "pulled before or after a purchase" edge from the potjes to the Betaalrekening. Only Buffer now sends money back to Samen, so the diagram suggests the other potjes never pay out, while the Spending routine (line 108) still pulls each purchase from its potje — `docs/household-finances.md:17` → fixed (docs: align salary routine, child benefit flow and flowchart in household finances)
- [ ] Nit: The document never says where the KGB lands or when it moves to Kinderen. The 21st rule assumes the KGB sits on the Betaalrekening from the 20th, while the flowchart sends child benefits straight to Kinderen — `docs/household-finances.md:96` → fixed (docs: align salary routine, child benefit flow and flowchart in household finances)
- [ ] Nit: "Kinderen keeps about one quarter of the kinderbijslag, because it arrives per quarter" reads as "a quarter of each payment stays"; the likely meaning is that Kinderen holds a quarter's worth in reserve between payments. The wording comes from the intent, so Etienne confirms the meaning — `docs/household-finances.md:63` → fixed (docs: align salary routine, child benefit flow and flowchart in household finances)

Compliance (intent acceptance criteria against the plan's `## Proof` checks, run this round):

- KGB under Inkomsten - Kindgebonden budget, not household income: App categories and Income sections — met.
- Leftover to Projecten on the 21st; no salary leftover to Buffer: Onvoorzien section; `salary leftover` grep finds nothing — met.
- Buffer emergencies only, three-month target, overflow to Projecten, in both files — met.
- Windfall destinations: Windfalls section — met.
- Ten potjes, all active; Cosimo and Kinderen kleding absent: 10 `| active |` rows; old-name grep finds nothing — met.
- Birthday party from Kinderen, aunt's gift from Cadeautjes: potjes table rows — met.
- Empty Boodschappen en huishouden example: Onvoorzien section — met.
- Onvoorzien is not a potje — met.
- Personal purchases on personal accounts — met.
- Credit card bill as a linked transfer: Fixed costs grep matches — met.
- App categories by name, no ids — met.
- Five methods named — met.
- `Words we use` rows for the seven terms: count is 7 — met.
- Glossary entries, alphabetical order, Buffer without salary: sort check prints `sorted` — met.
- Flowchart shows one salary, benefits to Kinderen, windfalls, leftover to Projecten: `mmdc` renders it — met, but see the Important finding.
- No euro amount, account number, potje code or category id: number inventory shows only dates, the 20th and 21st, and 13 from "13e maand"; the one `euro` hit is "every euro" in the Methods section — met.

Design: no `Avoid:` word in the diff; "envelope" appears only in "envelope budgeting". "surplus" appears only in the personal potje "Etienne's Buffer", as the plan allows.

## Round 2 — 2026-11-06T20:45Z — b08e969a

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes ran. The change is documentation only, so the Bugs and Security passes found nothing and no test or lint suite applies. The four Round 1 findings hold as fixed, except the flowchart edges noted below. The new child-benefit facts in the Salary routine match `.git/herdr/handoff-budget-bank.md` (KGB minus the children's savings to Kinderen on the 25th, kinderbijslag to Kinderen on the 2nd of each quarter).

- [ ] Important: Three places say Kinderen receives all child benefits: the Income section ("All child benefits go to Kinderen"), the Kinderen row of the potjes table (line 78) and the `Kinderen` entry in `GLOSSARY.md`. The Salary routine (line 91) and the flowchart (line 18) say the KGB first pays the children's own savings accounts and only the rest moves to Kinderen, which the bank handoff confirms. An agent that reconciles Kinderen against the KGB sees a monthly gap and can flag it or rebook the savings transfers. The three places say "child benefits, minus the children's own savings accounts" (or equivalent) — `docs/household-finances.md:66` → fixed (docs: Kinderen receives the KGB minus the children's savings and the kinderbijslag)
- [ ] Nit: The flowchart edge `Buffer -->|share above target| Projecten` draws money leaving Buffer. The Windfalls and Buffer sections (lines 95 and 115) and the bank handoff say something else: once Buffer is at its target, the 13e maand and vakantiegeld leftovers go to Projecten instead of Buffer; Buffer itself is never drained. An edge from the windfall nodes to Projecten ("rest, once Buffer is at target") matches the text — `docs/household-finances.md:31` → fixed (docs: flowchart shows windfall overflow to Projecten and potje pull-backs)
- [ ] Nit: Round 1's pull-back fix covered only the five salary potjes and Kinderen. Huis, Vakantie and Projecten still have no outgoing edge, while the Spending routine (line 111) pulls every purchase from its potje, so the diagram suggests they never pay out — `docs/household-finances.md:19` → fixed (docs: flowchart shows windfall overflow to Projecten and potje pull-backs)

Compliance (intent acceptance criteria against the plan's `## Proof` checks, run this round on b08e969a):

- KGB under Inkomsten - Kindgebonden budget, not household income: App categories and Income sections — met.
- Leftover to Projecten on the 21st; no salary leftover to Buffer: Onvoorzien section; `salary leftover` grep finds nothing; every Buffer hit read — met.
- Buffer emergencies only, three-month target, overflow to Projecten, in both files: all three terms in each — met.
- Windfall destinations: Windfalls section — met.
- Ten potjes, all active; Cosimo and Kinderen kleding absent: 10 `| active |` rows; old-name grep finds nothing — met.
- Birthday party from Kinderen, aunt's gift from Cadeautjes: potjes table rows — met.
- Empty Boodschappen en huishouden example: Onvoorzien section — met.
- Onvoorzien is not a potje — met.
- Personal purchases on personal accounts — met.
- Credit card bill as a linked transfer: Fixed costs grep matches — met.
- App categories by name, no ids: 3 names, no digits — met.
- Five methods named — met.
- `Words we use` rows for the seven terms: count is 7 — met.
- Glossary entries, alphabetical order, Buffer without salary: sort check prints `sorted`, 3 new entries, 0 salary hits — met.
- Flowchart shows one salary, benefits to Kinderen, windfalls, leftover to Projecten: `mmdc` renders it without error — met, but see the two flowchart nits.
- No euro amount, account number, potje code or category id: number inventory shows only date parts, the days 20 and 21, and 13 from "13e maand"; the one `euro` hit is "every euro" in the Methods section — met.

Design: no `Avoid:` word in the diff; "envelope" appears only in "envelope budgeting". "surplus" appears only in the personal potje "Etienne's Buffer", as the plan allows. One line per paragraph holds.

## Round 3 — 2026-11-06T20:48Z — eb30eef0

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes ran. The change is documentation only, so the Bugs and Security passes found nothing and no test or lint suite applies. The three Round 2 findings hold as fixed: the Income section, the Kinderen row and the flowchart now say the KGB pays the children's savings first, the windfall nodes send their rest to Projecten once Buffer is at target, and every spending potje has a pull-back edge. The 21st rule still holds against `.git/herdr/handoff-budget-bank.md`: the children's savings transfers leave on the 26th, so the full KGB is still on the Betaalrekening on the 21st.

- [ ] Nit: The `Kinderen` entry in `GLOSSARY.md` says Kinderen receives "the KGB minus the children's own savings and the kinderbijslag". Without a comma before "and", an agent can read that the kinderbijslag is also subtracted. The document's Kinderen row (line 78) has the comma and reads correctly. Put the kinderbijslag first: "the kinderbijslag and the KGB minus the children's own savings" — `GLOSSARY.md:6` → fixed (docs: align Buffer overflow wording and Kinderen glossary order)
- [ ] Nit: The Projecten row (line 86) and the Salary routine (line 91) say Projecten gets "Buffer's share above its target". Read alone, that is the same reading Round 2 removed from the flowchart: money that leaves Buffer once it is above its target. The Windfalls and Buffer sections (lines 95 and 115) say the windfall rests go to Projecten instead of Buffer. Use the same words in both places, for example "the windfall rests once Buffer is at its target" — `docs/household-finances.md:86` → fixed (docs: align Buffer overflow wording and Kinderen glossary order)

Compliance (intent acceptance criteria against the plan's `## Proof` checks, run this round on eb30eef0):

- KGB under Inkomsten - Kindgebonden budget, not household income: App categories and Income sections — met.
- Leftover to Projecten on the 21st; no salary leftover to Buffer: Onvoorzien section; `salary leftover` grep finds nothing; every Buffer hit read — met.
- Buffer emergencies only, three-month target, overflow to Projecten, in both files — met.
- Windfall destinations: Windfalls section — met.
- Ten potjes, all active; Cosimo and Kinderen kleding absent: 10 `| active |` rows; old-name grep finds nothing — met.
- Birthday party from Kinderen, aunt's gift from Cadeautjes: potjes table rows — met.
- Empty Boodschappen en huishouden example: Onvoorzien section — met.
- Onvoorzien is not a potje — met.
- Personal purchases on personal accounts — met.
- Credit card bill as a linked transfer: Fixed costs section — met.
- App categories by name, no ids: 3 names, no digits — met.
- Five methods named — met.
- `Words we use` rows for the seven terms: count is 7 — met.
- Glossary entries, alphabetical order, Buffer without salary: sort check prints `sorted` — met.
- Flowchart shows one salary, benefits to Kinderen (through the Betaalrekening), the windfalls, leftover to Projecten: `mmdc` renders it without error, including the `&` pull-back edge — met.
- No euro amount, account number, potje code or category id: number inventory shows only date parts, the days 20 and 21, and 13 from "13e maand"; the one `euro` hit is "every euro" in the Methods section — met.

Design: no `Avoid:` word in the diff; "envelope" appears only in "envelope budgeting". "surplus" appears only in the personal potje "Etienne's Buffer", as the plan allows. One line per paragraph holds.

## Round 4 — 2026-11-06T20:51Z — 0daf1850

No `REVIEW.md` or `REVIEW.local.md` in the repository; the reviewer's default passes ran. The change is documentation only, so the Bugs and Security passes found nothing and no test or lint suite applies. The two Round 3 nits hold as fixed: the `Kinderen` glossary entry names the kinderbijslag first, so the KGB alone loses the children's savings, and the Projecten row, the Salary routine, the Windfalls section, the Buffer section and both glossary entries now say the windfall rests go to Projecten once Buffer is at its target, never that money leaves Buffer. The flowchart edges say the same.

No findings.

Compliance (intent acceptance criteria against the plan's `## Proof` checks, run this round on 0daf1850):

- KGB under Inkomsten - Kindgebonden budget, not household income: App categories and Income sections — met.
- Leftover to Projecten on the 21st; no salary leftover to Buffer: Onvoorzien section; `salary leftover` grep finds nothing in either file; every Buffer hit read — met.
- Buffer emergencies only, three-month target, overflow to Projecten, in both files: all three terms in each — met.
- Windfall destinations: Windfalls section — met.
- Ten potjes, all active; Cosimo and Kinderen kleding absent: 10 `| active |` rows; old-name grep (with `Christmas`) finds nothing — met.
- Birthday party from Kinderen, aunt's gift from Cadeautjes: potjes table rows — met.
- Empty Boodschappen en huishouden example: Onvoorzien section — met.
- Onvoorzien is not a potje — met.
- Personal purchases on personal accounts — met.
- Credit card bill as a linked transfer: Fixed costs section — met.
- App categories by name, no ids: 3 names, no digits — met.
- Five methods named: each term found once in Methods — met.
- `Words we use` rows for the seven terms: count is 7 — met.
- Glossary entries, alphabetical order, Buffer without salary: sort check prints `sorted`, 3 new entries, 0 salary hits — met.
- Flowchart shows one salary, benefits to Kinderen (through the Betaalrekening), the windfalls, leftover to Projecten: `mmdc` renders it without error — met.
- No euro amount, account number, potje code or category id: number inventory shows only date parts, the days 20 and 21, and 13 from "13e maand"; the one `euro` hit is "every euro" in the Methods section — met.

Design: no `Avoid:` word in the diff; "envelope" appears only in "envelope budgeting". "surplus" appears only in the personal potje "Etienne's Buffer", as the plan allows. One line per paragraph holds.
