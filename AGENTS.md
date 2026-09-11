# Journal Administration

## What this is

A family household finance app. It imports bank transactions, categorizes them, tracks
budgets, keeps grocery receipts and product prices, and records durable possessions
(chattels) and their warranties. It also answers Model Context Protocol requests at `/mcp`,
so an AI assistant can read the books and file transactions on behalf of a user.

## Domain

- **Transaction** — single-table inheritance: `Credit`, `Debit`, `Transfer`. The type follows
  from whether the debitor/creditor `Account` is family-owned. A transaction can be split
  across several `Category`s via `TransactionSplit` (split total may not exceed the
  transaction amount); `Transfer` transactions cannot be split or categorized directly.
- **Account** — family-owned (`samen`, `etienne`, `michelle`, `serena`, `cosimo`, `chiara`) or
  external (shops, other banks). `AccountAlias` patterns match merchant names from bank
  imports to an external account.
- **Category** — hierarchical (parent/child), each has a `direction` (`debit`/`credit`). The
  `Transfer` category name is reserved and excluded from budgets.
- **Budget** — time-bounded, one active at a time: creating or updating a budget closes its
  predecessor automatically. Holds per-parent-category `BudgetCategory` allocations.
- **TransactionLink** — connects a `Debit`/`Credit` to the `Transfer` that covers it (e.g. a
  credit card bill and the transfer that pays it).
- **Receipt** / **ReceiptLine** — a grocery invoice and its line items. `Receipt#payment` is
  the bank `Transaction` that paid it; `rewrite_payment_splits` divides that payment across
  categories based on the basket, refusing if the basket doesn't fit the payment or the
  products aren't classified yet.
- **Product** / **ProductType** — a `Product` is a shop's own name for an item, resolved by a
  normalized name; a `ProductType` groups equivalent products across shops/brands and carries
  the `Category` they book to. A product without a `ProductType` and brand is "unclassified".
- **Chattel** — a durable possession, optionally linked to its purchase `Transaction`, with a
  warranty document and expiry.

## Commands

- Setup: `bin/setup` (bundle install, `db:prepare`, clears logs/tmp, starts `bin/dev`).
- Run: `bin/dev` (Rails + assets). Background jobs run inside Puma by default in development;
  set `SOLID_QUEUE_IN_PUMA=false` and run `bin/jobs` separately to change that.
- Test: `bin/rails test` (Minitest, fixtures under `test/fixtures`).
- Lint: `bundle exec rubocop`, `npx @herb-tools/linter app/views/` (ERB), `bundle exec brakeman
  --no-pager -q`, `bundle exec bundler-audit check`. Locale files must stay normalized:
  `bundle exec i18n-tasks normalize`.
- All of the above (plus tests) run automatically on `git push` via lefthook.

## Gotchas

- Rails binstubs resolve `APP_ROOT` to the main checkout, not the current worktree — when
  pushing from a `.worktrees/*` checkout, put that worktree's `bin/` first on `PATH` or
  pre-push hooks boot the wrong app.
- A worktree has no `node_modules` until `yarn install` runs there — without it the
  `herb-lint` pre-push hook fails with a misleading `.herb.yml` config error.
- `bundle install` prints "Fetching" lines from the `useragent` GitHub gem to stdout; don't
  pipe bundler output into a file you expect to be clean.
- Clear `tmp/cache/bootsnap` if code changes don't seem to take effect.
- Every user has an `assistant_token` for MCP access; regenerate it via
  `regenerate_assistant_token`, read it with `bin/kamal console`. The MCP endpoint only
  answers on the host named by `ASSISTANT_HOST`.
