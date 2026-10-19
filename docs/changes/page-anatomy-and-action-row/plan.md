# Plan: Page anatomy, index pages, and show and edit pages

From `intent.md` (2026-10-19). Status: accepted.

## Context

The specification is the rails-ui reference `agents/.agents/skills/rails-ui/references/interaction-design.md` on dotfiles `main` (24f3ea6). Read it before each phase. This plan names where each rule lands; it does not repeat the rules.

The app loads mvpa.css through `gem "mvpa-css", github: "eirvandelden/mvpa.css"` (no `ref:`), locked at `c2ce765`. mvpa.css `main` is at `70c730e` and includes #41 (`77697d4`, the button hierarchy and the `form > footer` action row).

The work runs in two phases with a gate between them.

- Phase 1, upstream, may start now: a pull request in eirvandelden/mvpa.css that adds a `<details>` pull-down menu and responsive table CSS.
- Phase 2, the app, starts only when both gates hold: PR #348 (`cents-instead-of-decimals`) is merged into `main`, and the Phase 1 pull request is merged by Etienne. Agents never merge. Before Phase 2 starts, rebase this branch onto `main` and re-verify every file named below against the code; #348 rewrites about 25 of the same views (money formatting).

## Design decisions

### Upstream (Phase 1)

- The pull-down menu is classless: a `<details>` inside `main > header nav`, with `position: relative` so its menu anchors to it. Its `<summary>` looks like the header's plain bordered button and gets a decorative `▾` through `summary::after { content: "▾" / "" }`, so the translated label holds no arrow. Its `<ul>` opens as an absolutely positioned surface under the summary (`inset-block-start: 100%`, `inset-inline-end: 0`), above the content. Each `li > a` and each `li > form > button` (a `button_to`) fills the menu's width as a menu item. Selector scope: `main > header nav details`; the sidebar's own `details` in `body > header` stays untouched. CSS lives in `2_modules/2_details.css`, so no new partial and no `demo.html` link-count change.
- The menu closes when its summary is clicked again or a page loads; it does not close on an outside click. That needs JavaScript, and the upstream scope is CSS only.
- Table width, in `2_modules/0_tables.css`, applies to every table: `max-inline-size: 100%`; `th, td { overflow-wrap: anywhere }`; `td :is(time, data) { white-space: nowrap }`. Dates and amounts are marked with the semantic `<time datetime>` and `<data value>` elements, not a class: mvpa.css keeps classes for buttons only.
- The content area is the query container: `1_layout/1_main.css` gives `main` `container-type: inline-size` and `min-inline-size: 0` (it is a grid item beside the sidebar on desktop). Table CSS never declares a container.
- Stacking is opt-in per table through `data-stack`, with three breakpoints in `rem`: `data-stack="narrow"` stacks below `30rem`, `"medium"` below `45rem`, `"wide"` below `60rem`. Each is an `@container (width < …)` rule. A container query cannot read a per-table value, so a fixed set of steps is the closest classless way to "pick the breakpoint per table". Rejected: one breakpoint for all tables (a nine-column table and a two-column table do not stop fitting at the same width); a class per breakpoint (mvpa.css keeps classes for buttons).
- Below its breakpoint a stacked table sets `display: block` on `table`, `thead`, `tbody`, `tfoot`, `tr`, `th` and `td`; hides `thead` with a clip-based visually hidden rule (never `display: none`); and shows `td::before { content: attr(data-label) / "" }` as the label column. Above the breakpoint the label stays hidden.
- The CHANGELOG gets a new dated section with `### Added` (menu, responsive tables) and `### Changed` (table width, `main` container), then `### Upgrading` with numbered steps: the menu markup; `data-stack`, `data-label` and the explicit roles (`role="table"`, `rowgroup`, `row`, `columnheader`, `cell`) on a stacking table; `<caption>` or `aria-labelledby`; `<time>`/`<data>` for dates and amounts; remove any own `overflow-x: auto` table wrapper.

### App (Phase 2)

- Bump: `bundle update mvpa-css` (approved in intent) moves the lock to mvpa.css `main` after Phase 1 merges. Apply the #41 `### Upgrading` steps and the Phase 1 steps. Checked against #41: the app has no own `--button-bg` rule, and no `<footer>` inside a form yet. The `type="button"` controls (search opener, budget add and remove category, transfer copy and share) turn plain, which is wanted.
- Native confirm: remove the custom `Turbo.config.drive.confirmationMethod` override from `app/javascript/application.js` and the `render "appkit/shared/confirm_dialog"` line from `layouts/application.html.erb` and `layouts/admin.html.erb`. Turbo then falls back to `window.confirm`. The intent's acceptance criterion requires the browser's confirm, and the reference forbids a custom confirmation dialog. This changes every existing `data-turbo-confirm` in the app (aliases, receipt unlink, merchant move) to the native confirm, which the reference also requires. The `confirm_verb` data attributes become dead; remove them where a touched line carries one, leave the others.
- Title bar: partial `app/views/shared/_title_bar.html.erb`, rendered with `render layout: "shared/title_bar", locals: { title: … } do … end`. It outputs `<header><h1>title</h1><nav>block</nav></header>` as a direct child of `main` (mvpa styles `main > header`); the `<nav>` is left out when the block is empty. It does not set `content_for(:title)`: pages keep their own `content_for(:title)` line, so `test/integration/page_title_test.rb` keeps its dashboard fallback.
- Title bar contents, left to right: existing back links (plain header buttons, unchanged), then the "Acties" menu when the page has one, then `Bewerken`, then `+ Nieuw` on index pages. No filled button in a title bar.
- Action row: partial `app/views/shared/_action_row.html.erb`, rendered as the last child of the form, locals `(form:, cancel_path:, submit_label: nil, delete_form_id: nil, confirm: nil)`. It outputs `<footer>` with, in DOM order: when `delete_form_id` is given, `button_tag t("common.delete_ellipsis"), form: delete_form_id, class: "button-danger", data: { turbo_confirm: confirm }`; then `link_to t("common.cancel"), cancel_path, role: "button", class: "button-secondary"`; then `form.submit(submit_label || t("common.save"))`. mvpa #41 then places `Verwijderen…` apart on the left and `Annuleren`, `Opslaan` right, `Opslaan` rightmost and filled.
- Delete form: partial `app/views/shared/_delete_form.html.erb`, locals `(record:, url:)`, outputs `form_with(model: record, url:, method: :delete, id: dom_id(record, :delete)) {}`. Each form partial renders it after its edit `<form>` closes, when the record is persisted and deletable, and passes the same `dom_id(record, :delete)` to the action row. An explicit `url:` is needed for admin users (`admin_user_path`) and STI transactions (`transaction_path`).
- `Verwijderen…` is a submit button whose form owner is the delete form, so it is not a submit button of the edit form; Return in a field presses `Opslaan`, the edit form's first submit button.
- `Annuleren` is an `<a>` because it navigates. mvpa.css styles a link as a button only with `role="button"`, and `.button-secondary` gives it the plain bordered look of a `type="button"`. Rejected: an upstream rule for links in `form > footer` (the intent limits this upstream round to the menu and tables). Tradeoff in Risks.
- `Annuleren` targets: an edit page goes to the record's show page, a new page to the index. Products and product types edit pages change from the index to the show page.
- Confirm text: new key `common.confirm_delete_named` with `%{name}`: nl `"%{name}" verwijderen? Dit kan niet ongedaan worden gemaakt.`, en `Delete "%{name}"? This cannot be undone.`, it `Eliminare "%{name}"? L'operazione non può essere annullata.`. The existing `common.confirm_destroy` stays for the inline deletes that slice 6 handles.
- New keys: `common.delete_ellipsis` (nl `Verwijderen…`, en `Delete…`, it `Elimina…`), `common.new` (nl `+ Nieuw`, en `+ New`, it `+ Nuovo`), `common.actions_menu` (nl `Acties`, en `Actions`, it `Azioni`). Remove the keys that the change leaves unused, in all three locales, then run `bundle exec i18n-tasks normalize`.
- Form errors: partial `app/views/shared/_form_errors.html.erb`, locals `(record:)`, outputs `<aside role="alert">` with an `h2` from `errors.template.header` and a `ul` of full messages, as the first child of the form (mvpa styles `aside[role="alert"]`). It replaces every `#error_explanation` div and every bare error `<div>` in record forms. Remove the now unused `#error_explanation` rules from `app/assets/stylesheets/local/modules/form_errors.css`.
- "Every form ends in a shared action row" is read as every form that creates or updates a record through its own page; in-place forms have no Cancel to place. Which forms get the action row: every record new and edit form (accounts, people, groups, categories, chattels, budgets, appropriations, transactions, products, product types, admin users), the profile edit form (`Annuleren`, `Opslaan`) and the CSV import form (`Annuleren` to the transactions index, submit `transactions.imports.new.submit`). Not, each with its reason: the dashboard and transactions filter forms and the search form (they filter in place, nothing to cancel); the Gebruikers role toggle (submits on change); the inline forms that slice 6 rebuilds as sheets (split add, link search, alias add, appropriation charge, receipt settle). The error aside goes on every form that renders model errors today except the split add form, which slice 6 rebuilds.
- Which edit pages get `Verwijderen…`: accounts, people, groups, categories, chattels, budgets, appropriations, transactions, admin users. Products and product types have no destroy route, so their edit pages show `Annuleren` and `Opslaan` only. The admin user edit page leaves `Verwijderen…` out when the user is `Current.user`, as the admin index does today.
- `Verwijderen…` on the admin user edit page uses the existing `Admin::UsersController#destroy`. The Gebruikers list's remove button used `UsersController#destroy` (deactivate); with the button gone that action has no caller. Keep its route, action and tests unchanged in this change; removing them is a separate clean-up.
- Budget form: `Bedragen voorstellen` (`budgets.form.suggest_amounts`) is a second submit of the edit form (`formaction`), and it must keep sending the unsaved field values. It moves after the `<footer>`, in its own `<p>`, so it follows `Opslaan` in tree order and Return still saves. `Categorie toevoegen` and the per-row remove stay `type="button"` inside the form body.
- Transaction edit page: the action row ends the transaction form; the page-bottom `div.actions` with Delete goes. The splits, appropriation and links sections below stay as they are (slice 6).
- Show pages as `<dl>`: accounts (`<p><b>` becomes `<dl>`), people, groups (members as one `dd`), budgets (date range and status), categories and chattels (both stop rendering their form with `disabled:`, so the `disabled:` local goes from both form partials), users profile show. Appropriations, transactions, products, product types, receipts and admin user show already use `<dl>`. The account show page keeps its ID line: the intent removes database IDs from index pages only.
- "Acties" menu: partial `app/views/shared/_actions_menu.html.erb` with a block, rendered inside the title bar's `<nav>`. Today only the transaction show page has a secondary command (`Nieuw bezit`), so it is the only user. The account commands stay in place (slice 6).
- Index rows: the record's name cell links to the record's show page; every per-row action column goes (Tonen, Bewerken, Verwijderen, Transacties bijwerken, admin Bekijken). Rows without a name link through another always-present cell: transactions through the amount, budgets through the date range, receipts through the date (as today). Accounts link `account.name.presence || account.account_number`.
- Todos: the description cell links to the item's record show page (transaction, product or account), which holds `Bewerken`, as the index-row rule requires. The action column goes, including the row's `Transacties bijwerken`; that command stays on the account show page.
- `+ Nieuw` sits in the title bar of each index page whose resource has a `new` route: transactions, accounts, people, groups, categories, chattels, budgets, appropriations, product types, admin users. Receipts, products, todos and the Gebruikers list have no `new` route, so they get none. The bare "new" links and paragraphs on those pages go.
- `h1` per page: add a title bar to accounts, categories, chattels and transactions indexes, todos, the dashboard (`t("home")`), the CSV import page (its `h2` becomes the `h1`), people and groups new and edit, products and product types new and edit (their bare `header` becomes the title bar). Pages that already have an `h1` move it into the title bar partial.
- Stacking tables (`data-stack`, `data-label` on every `td`, roles, a `<caption>` or `aria-labelledby` pointing at the section's `h2`, `<time>`/`<data>` on dates and amounts): every index table (transactions, accounts ×2, people, groups, categories, chattels, budgets, appropriations, receipts, products, product types, admin users, admin dashboard recent sign-ups, todos) and `shared/_recent_transactions.html.erb`, which is the transaction list on account and category pages. The `th` and its `td` call the same `t(...)`; assign the labels to a local hash at the top of the partial so the key is written once. Pick each table's `data-stack` step by loading it with realistic data and narrowing the window, as the reference describes; record the chosen step per table in the commit message.
- `shared/_recent_transactions.html.erb` loses its Tonen and Bewerken column; its amount links to the transaction.
- Transactions table and recent transactions: drop `truncate(20)` on the note, so a long description wraps instead of being cut. The acceptance criterion needs a long description to wrap.
- The dashboard balance table (up to eight columns) also stacks: `data-stack="wide"`, a `data-label` on every cell, roles.
- The remaining show-page tables have five columns or fewer (budget and appropriation show, receipt basket, product purchases, product type brands and months); the width rules make them fit, which `test/system/responsive_tables_test.rb` checks at phone width. If one still scrolls sideways there, it gets `data-stack="narrow"` and labels in this change. The slice 6 tables (splits, links, link suggestions and search results) are a bounded exception until slice 6 rebuilds them.
- Turbo frame responses are fragments, not pages, and get no `h1`: `searches/index` and `transaction_links/index` render only a `turbo-frame` for the search dialog and the link search.
- Failed deletes: accounts, people, groups and appropriations redirect a refused delete to the record's show page, which no longer holds Delete. Redirect it to the edit page instead, with the same alert, so the user stays where Delete lives.
- Not changed: `Uitloggen` turns red as a `DELETE` form (intent accepts it); inline deletes of splits, links and aliases; receipt `Ontkoppelen`; appropriation charge `Verwijderen`; payment-provider unmark.

## Integration points

- mvpa.css repository (`~/Developer/mvpa.css`, origin eirvandelden/mvpa.css): branch, push and draft pull request are approved in the intent. Its own workflow: `bundle exec rake test`, `npm run lint:css` (the repo moved from yarn to npm in #43), rubocop, `mvpa.css` manifest kept in sync by hand, `demo.html` sections, `README` literal examples.
- `mvpa-css` gem lock in `Gemfile.lock` (`bundle update mvpa-css` only).
- Turbo's confirm: default `window.confirm` once the override goes.
- appkit: the app stops rendering `appkit/shared/confirm_dialog`; appkit itself is not changed.
- PR #348 must merge first; Dependabot #331 is superseded and left alone.

## Files that change

### Phase 1 — mvpa.css

- `app/assets/stylesheets/mvpa/2_modules/2_details.css` — the header pull-down menu.
- `app/assets/stylesheets/mvpa/2_modules/0_tables.css` — width rules, `time`/`data` nowrap, `data-stack` steps, stacked layout, visually hidden header, `td::before` labels.
- `app/assets/stylesheets/mvpa/1_layout/1_main.css` — `container-type: inline-size` and `min-inline-size: 0` on `main`.
- `app/assets/stylesheets/mvpa/mvpa.css` — the same rules in the hand-maintained manifest.
- `demo.html` — a title bar with an "Actions" menu, a nine-column table with `data-stack="wide"`, a short table with `data-stack="narrow"`, long text cells, dates and amounts.
- `CHANGELOG.md` — new dated entry with `### Upgrading`.
- `test/details_menu_test.rb`, `test/responsive_tables_test.rb` (new) and the existing manifest, demo and changelog tests.

### Phase 2 — app

- `Gemfile.lock` — mvpa-css bump.
- `app/javascript/application.js` — remove the confirm override.
- `app/views/layouts/application.html.erb`, `app/views/layouts/admin.html.erb` — remove the confirm dialog render.
- `app/views/shared/_title_bar.html.erb`, `_action_row.html.erb`, `_delete_form.html.erb`, `_form_errors.html.erb`, `_actions_menu.html.erb` — new.
- `app/views/shared/_recent_transactions.html.erb` — stacking, amount link, no action column, no truncation.
- `app/controllers/accounts_controller.rb`, `people_controller.rb`, `groups_controller.rb`, `appropriations_controller.rb` — a refused delete redirects to the edit page.
- Accounts: `_form`, `edit`, `new`, `show`, `index`.
- People: `_form`, `edit`, `new`, `show`, `index`. Groups: `_form`, `edit`, `new`, `show`, `index`.
- Categories: `_form`, `edit`, `new`, `show`, `index`. Chattels: `_form`, `_table`, `edit`, `new`, `show`, `index`.
- Budgets: `_form`, `edit`, `new`, `show`, `index`. Appropriations: `_form`, `edit`, `new`, `show`, `index`.
- Transactions: `_form`, `_table`, `edit`, `new`, `show`, `index`, `imports/new`.
- Products: `_form`, `edit`, `index`, `show`. Product types: `_form`, `edit`, `new`, `index`, `show`. Receipts: `index`, `show`.
- Admin: `users/_form`, `users/edit`, `users/new`, `users/index`, `users/show`, `dashboard/index`.
- Users: `_user` (remove button goes), `index`, `profiles/edit`, `profiles/show`.
- `app/views/todos/index.html.erb`, `app/views/dashboard/index.html.erb`, `app/views/dashboard/_balance.html.erb`.
- `app/assets/stylesheets/local/modules/form_errors.css` — drop `#error_explanation` rules.
- `config/locales/en.yml`, `nl.yml`, `it.yml` — new keys, removed unused keys.
- Tests listed under Proof; existing tests that assert removed buttons or old placement change with the behaviour (for example `test/system/chattels_test.rb` "should destroy Chattel from show page" becomes a delete from the edit page).

## Order of work

### Phase 1 — mvpa.css (now)

1. In a worktree of `~/Developer/mvpa.css` on branch `pull-down-menu-and-responsive-tables`, write `test/responsive_tables_test.rb` for the width rules, run it, watch it fail.
2. Add the width rules to `0_tables.css` and the manifest; green.
3. Test, then add, the `main` container rules.
4. Test, then add, the `data-stack` steps and the stacked layout.
5. Test, then add, the pull-down menu.
6. Add the `demo.html` sections; check the demo in a browser at desktop width and at phone width, and with VoiceOver or the accessibility tree once for the stacked table.
7. Write the CHANGELOG entry; run `bundle exec rake test`, the CSS and Ruby linters.
8. Push the branch and open a draft pull request in eirvandelden/mvpa.css through that repository's own `review` and `deliver` steps. Etienne merges it.

### Phase 2 — app (after #348 and the Phase 1 pull request merge)

1. Rebase onto `main`; re-verify this file list against the code.
2. `bundle update mvpa-css`; run the full suite and fix bump fallout until green, before any view change.
3. Write the acceptance test for the account edit action row (`test/integration/accounts_edit_test.rb`), run it, watch it fail.
4. Remove the custom confirm override and the dialog render; the person-delete system test (written first) proves the native confirm.
5. Add the shared partials with the locale keys, test first per partial behaviour through the account pages.
6. Accounts: form, edit, new, show, index — make the account criteria green.
7. People and groups, then categories and chattels, then budgets and appropriations, then transactions (form, edit, show with the "Acties" menu, table, import page), then products, product types, receipts, then admin and users, then todos and the dashboard. Each resource: its tests first, then the views, then green.
8. Stacking tables: run the responsive system tests; pick each table's `data-stack` step with realistic data.
9. Remove unused locale keys and CSS; `i18n-tasks normalize`.
10. Full suite, rubocop, herb linter, brakeman, bundler-audit; check the pages in a browser on desktop and phone width.

## Risks

- `role="button"` on the `Annuleren` link makes a screen reader announce a button that navigates. Accepted for now to stay within mvpa.css's existing API; a later mvpa.css change can style `form > footer > a` as a plain button and drop the role.
- Removing the custom confirm dialog changes the look of every existing confirm in the app, including the inline ones slice 6 keeps. Intended by the reference; it also removes the last user of `data-confirm-verb`.
- Fixed `data-stack` steps may stack a table earlier than needed; a table that fits nowhere well can take a wider step.
- `container-type: inline-size` on `main` gives it inline-size containment. A child that relied on `main` growing with its content now overflows instead; the dashboard charts and the balance table are the pages to check.
- The inline deletes of transaction splits, transaction links and account aliases break the reference's rule for records with no editable fields until slice 6; the intent accepts this deferral.
- The `<details>` menu does not close on an outside click.
- The budget `Bedragen voorstellen` button sits below the action row, which looks a little detached.
- #348 rewrites money formatting in the same views. Any amount markup in this plan (`<data value>`) follows whatever helper #348 introduces.
- The phone action row stacks `Opslaan` on top while focus order stays `Verwijderen…`, `Annuleren`, `Opslaan` (accepted in the intent).

## Decisions settled by Etienne (2026-10-19)

- Account name: no model change. Prove the error alert with a duplicate account number. The intent criterion now says so.
- Upstream workflow: the mvpa.css pull request runs on Phase 1 of this plan, with its own review and draft pull request, and no separate intent or plan in that repository.
- Annuleren: a link, `<a role="button" class="button-secondary">`, as the reference requires. The intent criterion now says so.

## Out of scope

- Slice 2 rest: sheet, segmented control, count badges, confirm JavaScript in appkit.
- Slice 6: transaction edit workbench, splits, links, aliases and account commands; their inline deletes stay.
- Navigation (slice 7), clean-up (slice 8), the `UsersController#destroy` removal, Dependabot #331.
- Any model validation change, migration, other dependency, deploy or CI file.

## Proof

- On an account's edit page the bottom row shows a red `Verwijderen…` far left, then `Annuleren` and a filled `Opslaan`, `Opslaan` rightmost → `test/integration/accounts_edit_test.rb` `edit form ends in an action row of Verwijderen…, Annuleren and Opslaan` and `test/system/action_row_test.rb` `Verwijderen… stands apart on the left and Opslaan is rightmost`
- On the new-account page the bottom row shows only `Annuleren` and a filled `Opslaan`, on the right → `test/integration/accounts_edit_test.rb` `new form ends in an action row of Annuleren and Opslaan` and `test/system/action_row_test.rb` `new page action row sits on the right without Verwijderen…`
- Pressing Return in a field on an edit page saves the record and never asks to delete → `test/system/action_row_test.rb` `pressing Return in the account name saves the account`
- `Annuleren` on an edit page returns to the show page; on a new page to the index → `test/integration/accounts_edit_test.rb` `Annuleren on the edit page links to the account` and `Annuleren on the new page links to the accounts index`
- `Verwijderen…` on a person's edit page shows the browser's confirm naming the person and that it cannot be undone; cancelling keeps, confirming deletes → `test/system/people_test.rb` `dismissing the delete confirm keeps the person` and `accepting the delete confirm deletes the person`
- The show pages of an account, category, chattel, person and group show no Delete → `test/integration/accounts_show_test.rb` `show page has no delete button`, `test/integration/categories_show_test.rb` `show page has no delete button`, `test/integration/chattels_show_test.rb` `show page has no delete button`, `test/integration/people_test.rb` `show page has no delete button`, `test/integration/groups_test.rb` `show page has no delete button`
- The accounts, admin users, appropriations and budgets indexes show no per-row action buttons; a row's name opens the record → `test/integration/accounts_index_test.rb` `rows carry no buttons and the name links to the account`, `test/integration/admin/users_test.rb` `index rows carry no buttons and the name links to the user`, `test/integration/appropriations_test.rb` `index rows carry no buttons and the purpose links to the appropriation`, `test/integration/budgets_test.rb` `index rows carry no buttons and the date range links to the budget`
- Each index page has `+ Nieuw` in its title bar and shows no database IDs → `test/integration/index_pages_test.rb` `every index with a new route has + Nieuw in its title bar` and `no index shows a database ID column`
- Every page has exactly one `h1` → `test/integration/page_headings_test.rb` `every page has exactly one h1 in its title bar`
- On a transaction's show page `Nieuw bezit` sits in the "Acties" menu next to `Bewerken` → `test/integration/transactions_show_test.rb` `Nieuw bezit sits in the Acties menu beside Bewerken`
- Saving an account with a number another account already has shows the error in an alert above the form, announced by a screen reader → `test/integration/accounts_edit_test.rb` `a rejected save shows the errors in an alert above the fields`, `test/integration/people_test.rb` `saving a person without a name shows the error in an alert`, plus one manual VoiceOver or accessibility-tree check after a rejected save, recorded in the pull request
- A chattel's show page lists its fields as a description list → `test/integration/chattels_show_test.rb` `show page lists the fields as a description list`
- A refused delete returns to the edit page → `test/integration/people_test.rb` `a refused delete returns to the edit page with the reason`, and the same test in `accounts_edit_test.rb`, `groups_test.rb`, `appropriations_test.rb`
- On the Gebruikers list no row has a remove button; an administrator removes a user from the admin edit page after the native confirm → `test/integration/users_index_test.rb` `rows carry no remove button` and `test/system/admin_users_test.rb` `an administrator deletes a user from the edit page after the confirm`
- With the sidebar open on a laptop the transactions table never scrolls the page sideways; a long description wraps; amounts and dates stay on one line → `test/system/responsive_tables_test.rb` `transactions table fits beside the sidebar at laptop width`
- On a phone each transaction stacks, each value labelled with its translated column name, still a table with column headers to a screen reader → `test/system/responsive_tables_test.rb` `transactions table stacks into labelled rows at phone width` (computed `display`, `::before` content, header clipped not `display: none`, roles), plus one manual VoiceOver or accessibility-tree check recorded in the pull request
- The same width and stacking hold for every index table → `test/integration/index_pages_test.rb` `every index table stacks with a data-label on every cell` and `test/system/responsive_tables_test.rb` `no index page, show page or the dashboard scrolls sideways at phone width`
- A plain `Annuleren` looks like a bordered button beside a filled `Opslaan` → `test/system/action_row_test.rb` `Annuleren has a border and a different background from Opslaan`. The test asserts `<a role="button" class="button-secondary">` with the plain-button look of a `type="button"`
- Unlinking a receipt payment, removing an appropriation charge, deleting a split, a link or an alias still work from the same place → existing `test/integration/receipts_test.rb`, `appropriation_charges_test.rb`, `transaction_splits_test.rb`, `transaction_links_test.rb`, `account_aliases_test.rb`, unchanged and green

Per changed file, the unit tests expected:

- mvpa.css `2_modules/0_tables.css`: `table is never wider than its container`, `text cells break anywhere`, `time and data in a cell never wrap`, `data-stack narrow, medium and wide stack below 30, 45 and 60 rem`, `stacked header is clipped, not display none`, `stacked cell label is decorative attr(data-label)`.
- mvpa.css `1_layout/1_main.css`: `main is an inline-size container`, `main may shrink below its content`.
- mvpa.css `2_modules/2_details.css`: `header menu summary is a plain button with a decorative arrow`, `open header menu is positioned under its summary`, `sidebar details are not styled as a menu`.
- mvpa.css `mvpa.css`, `demo.html`, `CHANGELOG.md`: existing sync, demo-link and Upgrading tests stay green.
- `app/views/shared/_action_row.html.erb`: `renders Verwijderen…, Annuleren, Opslaan in that order`, `leaves Verwijderen… out without a delete form id`, `Verwijderen… points at the delete form and carries the confirm`.
- `app/views/shared/_delete_form.html.erb`: `renders an empty DELETE form with the dom_id delete id`.
- `app/views/shared/_title_bar.html.erb`: `renders one h1`, `leaves the nav out without a block`.
- `app/views/shared/_form_errors.html.erb`: `renders nothing for a valid record`, `renders an alert aside with every message`.
- `app/views/shared/_actions_menu.html.erb`: `renders a details menu with the translated summary`.

Test setup: integration tests sign in with `sign_in_as` and use the existing fixtures; add one transaction fixture with a long note and one account with a long name for the width tests. Partial tests are view tests under `test/views/shared/`. System tests use `accept_confirm`/`dismiss_confirm` for the native confirm, `current_window.resize_to` for laptop (1280×800) and phone (390×844), and `evaluate_script` with `getComputedStyle` and `getBoundingClientRect` for layout facts.

---
Domain skills applied: rails-ui (interaction-design reference), rails-testing, dependencies, object-oriented-design (no helpers or service objects; partials only).

## Critique

### Round 1 (Codex, terra)

- Phase 2 order had a deliberately red acceptance test before a step that requires a green full suite → fixed (the bump and its full-suite run now come first, the red acceptance test second)
- The empty-account-name criterion needs a validation `Account` lacks; the plan silently substituted another validation → fixed (recorded under Open decisions with the import evidence, a default path and the alternative)
- The criterion calls `Annuleren` a `type="button"` while the reference requires a navigating Cancel to be a link → fixed (the Proof line states the conflict and asserts `<a role="button" class="button-secondary">` with the plain look)
- Direct visits to `/searches` and the transaction-link search render no `h1` → fixed (Turbo frame fragments are named as a stated exception)
- "Every form" contradicted the excluded filter, inline and toggle forms → fixed (the reading and every excluded form with its reason are listed)
- The absolutely positioned menu had no positioned containing block → fixed (`position: relative` on the `details` and explicit insets on the menu)
- Todo rows linked to edit pages, against the row-opens-the-record rule → fixed (todo rows link to the record's show page)
- Wide tables outside the index list were left unstacked → fixed (the dashboard balance table stacks; show-page tables of five columns or fewer are checked at phone width and stack if they still scroll; slice 6 tables are a bounded exception)
- Inline alias and link deletes break the reference's no-editable-fields rule → dismissed: the intent's Flagged concerns chose to defer them to slice 6; the plan names this under Risks
- A refused delete redirects to the show page, which no longer holds Delete → fixed (accounts, people, groups and appropriations controllers redirect to the edit page, with regression tests)
- The proof checks `role="alert"` but not that a screen reader announces it → fixed (a manual VoiceOver or accessibility-tree check after a rejected save is added to the Proof)
