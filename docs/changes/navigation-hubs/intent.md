# Intent: Navigate by task hubs

Author: Etienne van Delden de la Haije. Status: accepted (2026-11-11). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

The menu lists every model: fifteen flat entries plus search, a Todo submenu, Profiel, Voorkeuren and Admin. Destinations sit next to account settings. Nothing tells the household where to start or what needs attention. On a phone the tab bar shows five of the fifteen entries and scrolls sideways. The highlight only marks an index page, so on a record's show or edit page no menu entry is marked. Admin pages use a separate layout with their own menu.

Amendment of 2026-11-11 (the intent was first accepted on 2026-10-25), after Etienne used the built branch: the user's name at the bottom of the rail opens a pop-up instead of a hub, wraps over four lines and has no emoji. On a phone it is not in the tab bar. Uploading a bank file and the consolidation list are hard to find: the upload is only a title-bar button, and "Te consolideren transacties" now goes by Categoriseren. The combined Te doen list is gone.

## Proposed outcome

The household navigates by what they want to do. A rail holds five task hubs: 🏠 Overzicht, 📥 Verwerken, 🗓️ Plannen, 🗄️ Administratie and 🛒 Boodschappen. Clicking a hub opens its landing page, with one tile per page and a count of what needs attention. On a wide screen a hub column next to the rail lists the pages of the current hub, with the same counts as badges. Account settings, set-up pages and signing out sit in the 👤 Profiel hub at the bottom of the rail, which works like every other hub: a landing page with tiles and, on a wide screen, a hub column. On a phone the rail is a six-tab bar, Profiel included, and the landing page is the list.

## Affected users and systems

- Every household member, on desktop and phone. Admins, whose pages move into the same shell.
- The application and admin layouts, the dashboard, the todo page, the title bar of every page (back link), and the index pages that get a new filter: products, receipts, chattels.
- The nl and en locale files.
- appkit: its `_nav` partial becomes the shell nav, which affects every app that uses appkit.
- mvpa.css: the rail, hub column, tile grid and count badges this slice uses.

## Constraints

- Follows the UI review decisions (artifact https://claude.ai/artifact/Btg62aW6itkPG4pZJiKFe6, sections "N2 worked out" and "Chosen: G2 with M2 and M3 combined") and the binding rails-ui interaction-design reference.
- The hub names stay: Overzicht, Verwerken, Plannen, Administratie, Boodschappen.
- A hub can grow past five pages. Contracten joins Administratie later.
- Rail, hub column and tile grid styles come from mvpa.css. A separate mvpa.css slice adds them first; this slice waits for it and then bumps the gem.
- Count badges come from the mvpa.css slice `sheets-segmented-control-badges` (#45, merged 2026-10-26 as `890d132`).
- appkit's shell nav merges before this app uses it. The same holds for the follow-up appkit change behind the Profiel hub; this app then bumps with the approved `bundle update appkit`. appkit's CHANGELOG gets an `### Upgrading` entry, written as steps an agent in another app can follow.
- Existing resource routes stay. Only the menu, the landing pages and the redirects change.
- Stays clear of the parallel slices `ui-review-bug-fixes` (this app) and `sheets-segmented-control-badges` (mvpa.css).
- Approved permissions: `bundle update appkit` and `bundle update mvpa-css`. Any other gem or package, migration, system tool or deploy file change is a stop-and-ask.

## In scope

- **Rail.** Search (🔍, opens today's search dialog; ⌘K keeps working) at the top, then the five hubs, then 👤 Profiel at the bottom.
- **👤 Profiel hub.** A hub like Plannen, with no pop-up anywhere: its rail item opens its landing page, and on a wide screen its hub column lists its items. Items, in this order: Gegevens (the user's profile, today's "Profiel"), Voorkeuren, Beheer, Uitloggen. Uitloggen is the last tile and the last hub-column item, and signs out at once. Beheer opens the Beheer landing page.
- **Hub pages:**
  - 🏠 Overzicht: the dashboard. It is its own landing page and has no hub column.
  - 📥 Verwerken, in this order: Consolideren (transactions that need consolidation: no category, a split without a category, or splits that do not add up to the amount; the list Categoriseren shows today), Rekeningen indelen (untouched accounts), Producten classificeren (unclassified products), Importeren (opens the bank-file upload; no count), Alles (every open item of the three lists in one list, newest first, as Te doen → Alle was; its tile shows the total). Importeren also stays as the title-bar action on the Verwerken landing page.
  - 🗓️ Plannen: Budgetten (tile: the active budget, spent and remaining) and Begrotingsposten (tile: count with money left).
  - 🗄️ Administratie: Journaal, Rekeningen, Bezittingen (tile: count whose warranty ends within 90 days).
  - 🛒 Boodschappen: Facturen (tile: count without a linked payment), Producten (tile: count of unclassified products, the same count and list as Verwerken's Producten classificeren).
- **Beheer**, from the Profiel hub, stays its own hub with a landing page and hub column, and no rail item of its own; on its pages the rail marks Profiel. Its pages: Categorieën, Productsoorten, Gezinsleden, Groepen, and for admins only Gebruikers and the admin dashboard. Every user may open Beheer and edit categories.
- **Landing page** per hub: one tile per page. A tile with a count shows it, also when it is 0. A tile opens that page's list, filtered where the count is filtered.
- **Hub column** next to the rail on a wide screen: the hub name (linking to the landing page), then its pages, each with a badge carrying the tile's count. A count of 0 shows no badge.
- **Narrow window above phone width:** the hub column hides and the landing page takes over.
- **Phone:** the rail becomes a six-tab bar: the five hubs and Profiel. The landing page is the list. Search sits in the title bar. No title bar holds an avatar; the Profiel tab is the way in.
- **New filtered lists** behind the tiles: unclassified products, receipts without a linked payment, chattels whose warranty ends within 90 days, this year's appropriations with money left.
- **Highlight.** The rail marks the hub that owns the current page, and the hub column marks the page, also on nested pages (show, edit, new). Verwerken owns its filtered lists. A record opened from them belongs to its own hub: a transaction lights Administratie.
- **Origin-aware back link.** A page opened from a landing tile shows "‹ <hub>" in its title bar and returns to that landing page, even when the page belongs to another hub. A record opened from that list returns to the list. The origin survives show → edit → save or cancel. After Verwijderen… the user lands on the origin landing page. Without an origin, the back link goes to the record's index page, as today.
- **Te doen** goes as a menu entry. Its combined list returns as Verwerken's Alles page, served at `/todo`, so old bookmarks open it.
- **MCP:** no new tool. Alles and the landing pages only combine what `find_uncategorized_transactions`, `find_accounts` and `list_unclassified_products` already answer, so they get a reason in the parity map's exclusions. Signing out has no tool.
- **Admin** pages use the app shell. The separate admin layout goes.
- **appkit:** `_nav` becomes the shell nav (rail, hub column, Profiel hub), fed by one menu map, with an `### Upgrading` changelog entry. The account pop-up merged in appkit #24 gives way, in a follow-up appkit change with its own intent, to a hub whose items may include a sign-out action. That change merges before this app bumps appkit again.
- **mvpa.css:** #54 hides the account `<li>` that holds a `<details>` in the phone bar, and styles the account pop-up and its title-bar copy. A Profiel hub link shows in the phone bar without a CSS change, so this app does not wait for mvpa.css. Removing the unused pop-up CSS is a follow-up mvpa.css change with its own intent.

## Out of scope

- The mvpa.css work itself: rail, hub column, tile grid (their own slice) and count badges (`sheets-segmented-control-badges`).
- Segmented controls and sheets, including a "Nieuwe categorie…" sheet next to the category picker.
- The Contracten page.
- The fixes in `ui-review-bug-fixes` (labels, profile "Terug" target, accounts pager and the others).
- Renaming or moving existing resource routes.
- The dashboard's content.
- The MCP endpoint.

## Acceptance criteria

- The rail shows 🔍, Overzicht, Verwerken, Plannen, Administratie, Boodschappen and 👤 Profiel, and nothing else; no rail item opens a pop-up.
- With 12 transactions that need consolidation, the Verwerken landing page shows a Consolideren tile with 12, and the hub column shows a 12 badge next to Consolideren.
- A transaction of € 100 split into € 60 for Boodschappen and € 40 without a category counts on the Consolideren tile and shows in its list.
- With every account classified, the Rekeningen indelen tile shows 0 and the hub column shows no badge next to it.
- Clicking the Consolideren tile opens the journal filtered to transactions that need consolidation, with "‹ Verwerken" in the title bar.
- Opening a transaction from that list, pressing Bewerken and then Opslaan returns to the transaction, whose back link still returns to the filtered list, which still leads back to Verwerken.
- Deleting a transaction opened from a Verwerken tile lands on the Verwerken landing page.
- A transaction opened from search shows a back link to the Journaal.
- On a transaction's edit page, the rail marks Administratie and the hub column marks Journaal.
- On a budget's show page, the rail marks Plannen and the hub column marks Budgetten.
- A chattel whose warranty ends in 60 days counts on the Bezittingen tile; one whose warranty ends in 120 days does not.
- A receipt without a linked payment counts on the Facturen tile, and the tile opens the receipts list filtered to those.
- With no active budget, the Budgetten tile says so and opens Budgetten.
- With one appropriation with money left and one spent in full, the Begrotingsposten tile shows 1 and opens the appropriations filtered to those with money left.
- Overzicht opens the dashboard, with no hub column.
- The Verwerken hub column lists Consolideren, Rekeningen indelen, Producten classificeren, Importeren and Alles, in that order.
- Clicking the Importeren tile or hub-column item opens the bank-file upload; the Verwerken landing page still has Importeren in its title bar.
- With 2 transactions to consolidate, 1 untouched account and 1 unclassified product, the Alles tile shows 4, and the Alles page lists those 4, newest first.
- Opening `/todo` shows the Alles page, with the rail on Verwerken and the hub column on Alles.
- Clicking 👤 Profiel opens its landing page with the tiles Gegevens, Voorkeuren, Beheer and Uitloggen, and on a wide screen a hub column with the same four.
- Clicking Uitloggen, as a tile or in the hub column, signs the user out and shows the sign-in page.
- On Voorkeuren, on the Beheer landing page and on Categorieën, the rail marks Profiel.
- A family member who is not an admin sees Categorieën, Productsoorten, Gezinsleden and Groepen in Beheer, and no Gebruikers.
- An admin sees Gebruikers and the admin dashboard in Beheer, inside the same rail.
- At phone width, the bottom bar shows exactly six tabs: the five hubs and Profiel, and no title bar holds an avatar.
- In a window narrower than the hub-column width but wider than a phone, the hub column is gone and the landing page is reachable from the rail.
- No page scrolls sideways at any width.

## Flagged concerns

- This slice depends on an mvpa.css slice for the rail, hub column and tile grid that has no intent yet, and on the `sheets-segmented-control-badges` slice for badges, which merged on 2026-10-26 (#45, `890d132`). Chosen side: wait for both (upstream first), so the app PR merges after them; only the rail slice remains.
- Replacing appkit's `_nav` changes every app that uses appkit. Chosen side: replace it, and document the steps in appkit's `### Upgrading` entry.
- The Profiel hub undoes the account pop-up that merged in appkit #24 and mvpa.css #54, so this slice waits for one more appkit change. Chosen side: upstream first again; the app bumps appkit after it merges, and the mvpa.css cleanup does not block the app.
- The rail highlights the owning hub, while the back link returns to the origin hub. A transaction opened from Verwerken lights Administratie and leads back to Verwerken. Chosen side: both, as decided.

## Decisions

- The hub column hides below a set width, above phone width, and the landing page takes over — recommended option chosen; replaces the 11 Oct "never hidden" remark.
- Rail, hub column and tile grid styles go upstream into mvpa.css first, in their own slice — no reason given.
- Groepen moves to Beheer, next to Gezinsleden — no reason given.
- Verwerken replaces Te doen, and `/todo` redirects there — recommended option chosen. Replaced on 2026-11-11: `/todo` serves the Alles page.
- Admin pages move into the app shell; Gebruikers sits in Beheer — recommended option chosen.
- The rail highlights the hub that owns the page, not the hub you came from — no reason given.
- The origin-aware back link "‹ <hub>" is part of this slice — no reason given.
- A page with no origin goes back to the record's index page — recommended option chosen; nothing changes outside the tile flow.
- The origin survives show → edit → save or cancel; after delete the user lands on the origin landing page — recommended option chosen.
- Each tile opens its filtered list; this slice adds the missing filters — recommended option chosen.
- Warranty "ends soon" means within 90 days — recommended option chosen; enough time to claim.
- A tile with nothing to do shows 0; the hub column shows no badge — recommended option chosen.
- The shell nav goes into appkit in this slice — no reason given.
- Search sits at the top of the rail on a wide screen — recommended option chosen.
- On a phone the account avatar sits only in the Overzicht title bar — Etienne: "i do want the avatar to be only on the Overzicht page, not every header". Replaced on 2026-11-11: no avatar.
- appkit's `_nav` is replaced, not kept beside the new partial — no reason given.
- Approve `bundle update appkit` and `bundle update mvpa-css` up front — no reason given.
- Autonomous delivery, no Codex review — no reason given.
- The Boodschappen Producten tile counts unclassified products (no type or no brand), the same as Verwerken — recommended option chosen; one definition, one list.
- The Begrotingsposten tile opens a new "money left" filter, not the unfiltered list (decided after the plan stage, 2026-10-25) — recommended option chosen; a tile opens its list filtered where the count is filtered.
- 2026-11-11: the account item is a hub like Plannen, with no pop-up, and the sixth tab on a phone — Etienne, after using the built branch.
- 2026-11-11: the hub is called 👤 Profiel, and its profile item becomes Gegevens — no reason given.
- 2026-11-11: Uitloggen is a tile and a hub-column item that signs out at once — no reason given.
- 2026-11-11: Beheer stays its own hub, reached from the Profiel hub, which the rail marks on Beheer pages — recommended option chosen.
- 2026-11-11: no avatar in any title bar; the Profiel tab is the way in — recommended option chosen.
- 2026-11-11: Categoriseren is renamed Consolideren, the same list and count, rather than a second page — recommended option chosen; the list already holds every transaction that needs consolidation.
- 2026-11-11: Importeren becomes a Verwerken tile and hub-column item, and stays in the title bar — recommended option chosen.
- 2026-11-11: the combined Te doen list returns as Alles, the last Verwerken item, at `/todo` — no reason given.

## Amendment of 2026-11-11: reachability audit

Every destination in the old menu (`layouts/application.html.erb` and `layouts/admin.html.erb` on `origin/main`) against the menu map. The dashboard on `origin/main` links only to itself, through its period filter.

| Old menu entry | Where it is now |
|---|---|
| Zoeken | Rail search |
| 🏠 Thuis | 🏠 Overzicht |
| 📔 Journaal, 🏦 Rekeningen, 📦 Bezittingen | 🗄️ Administratie |
| 💰 Budgetten, 🎁 Begrotingsposten | 🗓️ Plannen |
| 🛒 Producten, 🧾 Facturen | 🛒 Boodschappen |
| 🏷️ Categorieën, 🥫 Productsoorten, 👤 Personen (now Gezinsleden), 👥 Groepen | Beheer |
| 🥷 Beheer (admin dashboard), admin Gebruikers | Beheer, admins only |
| 👤 Profiel, 🎨 Voorkeuren | 👤 Profiel hub: Gegevens and Voorkeuren |
| Te doen → Te consolideren transacties (`/transactions?filter=no_category`) | 📥 Verwerken → Categoriseren: the same filter and the same list, renamed |
| Te doen → Te consolideren rekeningen (`/accounts?filter=untouched`) | 📥 Verwerken → Rekeningen indelen: the same list, renamed |
| Te doen → Nieuwe transacties uploaden | Only the Importeren action in Verwerken's title bar: no tile, no hub-column item |
| Te doen → Alle (`/todo`, one date-sorted list of transactions, accounts and products) | Gone: `/todo` redirects to the Verwerken landing page |
| Admin → Terug naar site | Not needed: admin pages use the app shell |

Consolidation: `Transaction.uncategorized`, behind Categoriseren, already selects partly split transactions: a split without a category, or splits that do not add up to the amount. On the development data it holds the same 8558 of 15543 transactions as `Transaction#consolidatable?`. No list of consolidatable transactions is missing; the old name "Te consolideren transacties" is.

After this amendment, the last three gaps close: Categoriseren is Consolideren, uploading is a Verwerken tile and hub-column item, and the combined list returns as Alles at `/todo`.

## Open questions

None.
