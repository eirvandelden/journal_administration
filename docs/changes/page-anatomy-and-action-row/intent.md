# Intent: Page anatomy, index pages, and show and edit pages

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-19). Type: feature. Delivery: autonomous.

## Problem

Every button in the app looks like the main action, so a page cannot show which action is the default. Each template decides where its actions go: the title bar, a paragraph above the content, a card, a footer or a `div.actions`. Delete sits on show pages, in index table rows, and in footers outside the form on edit pages. Deleting a person or a group asks for no confirmation at all. Several pages (accounts, categories, chattels, transactions, transaction links, todos, the dashboard) have no `h1`. Index rows carry action columns and database IDs instead of opening the record. Wide tables push the page sideways, beside the sidebar and on a phone.

## Proposed outcome

UI-review slices 3 (page anatomy), 4 (index pages) and 5 (show and edit pages) ship together. The review is the artifact https://claude.ai/artifact/Btg62aW6itkPG4pZJiKFe6. The app runs on mvpa.css with PR #41 and follows the rails-ui reference `interaction-design.md` on dotfiles main (`agents/.agents/skills/rails-ui/references/interaction-design.md`). That reference is the specification; this intent does not repeat it.

- Page anatomy: every page has an `h1` in a shared title bar. Every form ends in a shared action row. An "Acties ▾" pull-down menu holds a show page's secondary commands. Form errors render as `<aside role="alert">`.
- Index pages: a row opens its record. No per-row action columns. "+ Nieuw" sits in the title bar. No database IDs. Every cell has a `data-label`, and a table that does not fit stacks into labelled rows.
- Show and edit pages: a show page lists its fields as a `<dl>`. Delete lives only on the edit page: a red `Verwijderen…` apart on the far left of the action row, confirmed by the browser's native confirm.

## Affected users and systems

- Every signed-in family member, on desktop and on a phone.
- The `mvpa-css` gem, pinned at `c2ce765`. Dependabot #331 bumps it only to `53caa59` (2026-09-23), which predates #41 (`77697d4`). This change bumps it to mvpa.css main itself.
- Upstream eirvandelden/mvpa.css: a `<details>` pull-down menu and responsive table CSS, added in their own pull request.
- All index, show, new and edit views, their form partials, and the `en`, `nl` and `it` locales.

## Constraints

- The interaction-design reference on dotfiles main is binding: action rows, edit pages, confirmation dialogs (native confirm through `data-turbo-confirm`), where Delete lives, default button, table width, responsive tables, screen readers.
- Follow the `### Upgrading` steps of the mvpa.css CHANGELOG entry of 2026-10-13 (#41).
- Upstream first: the mvpa.css pull request (menu and responsive tables, with an `### Upgrading` entry in its dated CHANGELOG section) merges before the app uses those parts. Only the menu, the table CSS and the title-bar row layout (`main > header nav` as a wrapping row, added by Etienne on 2026-10-19) go upstream now; the sheet, segmented control and badges stay in slice 2.
- Ordering against PR #348 (cents-instead-of-decimals): the plan and the upstream mvpa.css work may start now. The app view changes branch from main only after #348 merges; rebase onto it before touching app views.
- Approved permissions: `bundle update mvpa-css`; a branch, push and draft pull request in eirvandelden/mvpa.css. Anything else (another gem or package, a migration, deploy or CI files) is a stop-and-ask.
- Every label is translated in `en`, `nl` and `it`. `Verwijderen…` keeps its ellipsis in every language.

## In scope

- Bump mvpa-css to mvpa.css main, including #41 and the new upstream menu and table CSS, and apply their Upgrading steps.
- Upstream in mvpa.css: a `<details>` pull-down menu and responsive table CSS (width rules and container-query stacking), shown in `demo.html`.
- A shared title bar partial and a shared action-row partial, used by every page and form. Existing back links stay, as plain buttons.
- An "Acties ▾" menu partial. Every show page moves its secondary commands into it, except the account commands that slice 6 handles. Example: "Nieuw bezit" on a transaction's show page.
- Form errors as `<aside role="alert">` on every form.
- An `h1` on every page.
- Index pages: rows link to the record; remove per-row action columns (including Delete in the accounts, admin users, appropriations and budgets rows); "+ Nieuw" in the title bar; hide database IDs; `data-label` on every cell; table width and stacking per the reference.
- Show pages as `<dl>`; remove Delete from the show pages of accounts, categories, chattels, people and groups.
- Edit pages: one action row with `Verwijderen…`, `Annuleren` and `Opslaan`, as the reference describes, on every edit page whose record can be deleted. New pages show only `Annuleren` and `Opslaan`.
- Users: remove the per-row "remove from account" button from the Gebruikers list; the admin user edit page gets `Verwijderen…` in its action row. The inline role toggle stays.

## Out of scope

- The rest of slice 2: sheet, segmented control, count badges, and moving confirm JavaScript into appkit.
- Slice 6: the transaction edit workbench, splits, appropriation and transfer links as show-page sections with sheets, alias add sheet, account commands moving into "Acties ▾". Until then, transaction splits, transaction links and account aliases keep their inline Delete.
- Clearing a link is not a delete: receipt `Ontkoppelen`, appropriation charge `Verwijderen` and account payment-provider unmark stay where they are. As DELETE forms they turn red.
- Restyling `Uitloggen`: it turns red as a DELETE form.
- Navigation (slice 7) and clean-up items (slice 8).
- Closing Dependabot #331; this change supersedes it, and Etienne decides what happens to it.

## Acceptance criteria

- On an account's edit page, the bottom row shows a red `Verwijderen…` on the far left, and `Annuleren` and a filled `Opslaan` on the right, with `Opslaan` rightmost.
- On the new-account page, the bottom row shows only `Annuleren` and a filled `Opslaan`, on the right.
- Pressing Return in a field on an edit page saves the record; it never asks to delete.
- `Annuleren` on an edit page returns to the record's show page; on a new page it returns to the index.
- Clicking `Verwijderen…` on a person's edit page shows the browser's confirm, naming the person and that this cannot be undone. Cancelling keeps the person; confirming deletes them.
- The show pages of an account, a category, a chattel, a person and a group show no Delete button.
- The accounts, admin users, appropriations and budgets indexes show no Delete or other per-row action buttons; clicking a row's name opens that record.
- Each index page has "+ Nieuw" in its title bar and shows no database IDs.
- Every page, including the dashboard, transactions, accounts and todos, has exactly one `h1`.
- On a transaction's show page, "Nieuw bezit" sits in the "Acties ▾" menu, next to `Bewerken`.
- Saving an account with a number another account already has shows the error in an alert above the form, and a screen reader announces it.
- A chattel's show page lists its fields as a description list.
- On the Gebruikers list, no row has a remove button; an administrator removes a user from that user's admin edit page, after the native confirm.
- With the sidebar open on a laptop, the transactions table never makes the page scroll sideways; a long description wraps, and amounts and dates stay on one line.
- On a phone, each transaction in the table shows as a stacked block, each value preceded by its translated column name; a screen reader still announces it as a table with column headers.
- The same width and stacking hold for every index table.
- `Annuleren` is a link that looks like a plain bordered button beside a filled `Opslaan`.
- Unlinking a receipt's payment, removing an appropriation charge, deleting a transaction split, a transaction link or an account alias still work from the same place as today.

## Flagged concerns

- The reference says Delete lives only on the edit page, but this change leaves the inline Delete of transaction splits, transaction links and account aliases until slice 6 rebuilds those sections. Chosen side: defer to slice 6.
- `Uitloggen` is a DELETE form, so mvpa.css #41 turns it red, although signing out destroys nothing. Chosen side: accept the library default; it stays red.
- On a phone the stacked action row shows `Opslaan` on top, while keyboard focus order stays `Verwijderen…`, `Annuleren`, `Opslaan` (WCAG 2.4.3 tension). Chosen side: accept the mismatch as a known tradeoff.
- Waiting for #348 delays the app half of this change; running in parallel would mean conflicts in about 25 shared views. Chosen side: wait for #348.

## Open questions

None.
