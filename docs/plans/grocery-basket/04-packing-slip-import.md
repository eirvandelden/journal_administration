# Phase 04 — Read the packing slip

Read `00-context.md` first.

## What the mailbox actually holds

Albert Heijn never mails an invoice. The delivery mail says so itself: *"Je factuur kun je bekijken
na bezorging … in de AH app of op ah.nl"*. The old packing-slip mails ("Alsjeblieft, hier is je
pakbon") stopped in January 2024.

Two mails carry a basket, both from `bestellingen@ah.nl`:

| Mail | When | What it is |
| --- | --- | --- |
| "Bedankt voor jouw bestelling" | at order time, and again after every change | the basket as ordered |
| **"Je boodschappen komen eraan!"** | delivery morning, once packed | the basket as actually packed |

The second is the one we read. The owner files these into a mail folder; they arrive in the inbox
first. Several can share one `Bestelnummer` — Albert Heijn sends a fresh slip whenever the order
changes — and the latest one wins.

A slip carries: order number, delivery date, every product with quantity, unit price and line total,
a separate bonus block naming the product each discount came off along with its promotion ("2 VOOR
3.49", "1 + 1 GRATIS", "30% KORTING"), free extras under "Gratis toegevoegd", the deposit and bag
fees under "Overig", and the totals. Its arithmetic reconciles: shelf total − bonus + other = total.

There is no pack size anywhere in it, and no PDF attached, ever. A product sold by weight has
`gew.` where the unit price would be, a quantity of 1, and the weighed price as its line total.

## Done

**Step 1 — the parser.** `Importing::AlbertHeijn::PackingSlip.parse` reads a slip's text into an
order number, a delivery date, a total, and a line per product with its bonus folded in. Free extras
are skipped: they are not purchases. Tested against a real slip saved as
`test/fixtures/files/albert_heijn_packing_slip.txt`, with the household's details replaced.

**Step 2 — the import.** `Importing::AlbertHeijn::ImportJob.perform(mail)` records the delivery and
its basket, resolving each line to a product by name and creating unclassified ones as needed. The
delivery is keyed on its order number, so a re-sent slip replaces the basket rather than adding a
second delivery. Nothing is matched to a payment automatically.

Along the way, two decisions from the design changed against real data:

- **Payments are offered by shop and date, never by amount.** Empty crates, bottles and cans are
  settled at the door and appear only on the online invoice, so the bank charge rarely equals the
  slip's total. A person confirms which payment settled a delivery.
- **Imported lines carry no pack size**, since the slip has none. They therefore have no price per
  unit, and the shrinking-pack question can only be answered for lines where someone recorded a pack
  size by hand.

## Step 3 — the MCP tool (not started)

The remaining piece: an agent reads the slip through an email MCP server and hands its text to this
app through a tool on the app's own MCP endpoint.

That endpoint is being built on branch `ai/mcp-server` in `.worktrees/mcp-server`. If it has not
landed, stop here and report — nothing else depends on this step.

- Tests: calling the tool with a slip's text answers with what was imported and which delivery it
  belongs to; calling it without a valid token is refused; handing over the same slip twice changes
  nothing.
- Register one tool on the existing endpoint, taking the mail text as its only argument and calling
  the import job. Use whatever authentication that branch established; add no second scheme and no
  second endpoint.

## Out of scope

- Fetching anything from Albert Heijn directly, including their app's undocumented interface.
- Reading mail from inside the app: no Action Mailbox, no IMAP polling, no mail credentials.
- A scheduled job that imports by itself. The agent decides when to hand something over.
- Parsing the "Bedankt voor jouw bestelling" mail, or the "Er was iets mis bij je bestelling" mail
  that Albert Heijn sends when something went wrong with an order.
- Any other shop: this parser knows Albert Heijn's slip only.
