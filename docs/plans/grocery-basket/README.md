# Groceries: basket, prices and invoices

A handoff plan. Groceries arrive from Albert Heijn every Friday; this feature records what was in the
basket, what each product cost, and whether it was on bonus, and splits the payment accordingly.

Read the files in order. `00-context.md` is required before any phase — it holds the design decisions,
what already exists on the branch, the repository's conventions, and the traps.

| File | Phase | State |
| --- | --- | --- |
| `00-context.md` | Context, decisions, conventions, traps | Read first |
| `01-receipt-pages.md` | See and settle receipts | Done |
| `02-classify-products.md` | Classify products, todo list | Done |
| `03-price-history.md` | Price history, chart, brand comparison | Not started |
| `04-invoice-import.md` | Parse a real invoice and import it | Blocked on a real invoice mail |
| `05-finish-the-branch.md` | Sync, verify, pull request | Last |

Phases 01 to 03 are independent of 04 and can be done in any order, though the order above is the one
that makes the app usable soonest. Each phase file names the decisions to settle with the owner before
starting it.

Work happens on branch `ai/grocery-basket`, in a worktree under `.worktrees/`, never in the main
checkout.
