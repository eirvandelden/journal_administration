# Intent: Navigate by task hubs

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-25). Type: feature. Delivery: autonomous. Codex review: no.

## Problem

The menu lists every model: fifteen flat entries plus search, a Todo submenu, Profiel, Voorkeuren and Admin. Destinations sit next to account settings. Nothing tells the household where to start or what needs attention. On a phone the tab bar shows five of the fifteen entries and scrolls sideways. The highlight only marks an index page, so on a record's show or edit page no menu entry is marked. Admin pages use a separate layout with their own menu.

## Proposed outcome

The household navigates by what they want to do. A rail holds five task hubs: 🏠 Overzicht, 📥 Verwerken, 🗓️ Plannen, 🗄️ Administratie and 🛒 Boodschappen. Clicking a hub opens its landing page, with one tile per page and a count of what needs attention. On a wide screen a hub column next to the rail lists the pages of the current hub, with the same counts as badges. Account settings and set-up pages sit in an account menu under the user's name. On a phone the rail is a five-tab bar and the landing page is the list.

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
- Count badges come from the parallel mvpa.css slice `sheets-segmented-control-badges`.
- appkit's shell nav merges before this app uses it. appkit's CHANGELOG gets an `### Upgrading` entry, written as steps an agent in another app can follow.
- Existing resource routes stay. Only the menu, the landing pages and the redirects change.
- Stays clear of the parallel slices `ui-review-bug-fixes` (this app) and `sheets-segmented-control-badges` (mvpa.css).
- Approved permissions: `bundle update appkit` and `bundle update mvpa-css`. Any other gem or package, migration, system tool or deploy file change is a stop-and-ask.

## In scope

- **Rail.** Search (🔍, opens today's search dialog; ⌘K keeps working) at the top, then the five hubs, then the user's name at the bottom, which opens the account menu.
- **Account menu.** Profiel, Voorkeuren, Beheer, Uitloggen.
- **Hub pages:**
  - 🏠 Overzicht: the dashboard. It is its own landing page and has no hub column.
  - 📥 Verwerken: Categoriseren (transactions without a category), Rekeningen indelen (untouched accounts), Producten classificeren (unclassified products), and Importeren as an action in the title bar.
  - 🗓️ Plannen: Budgetten (tile: the active budget, spent and remaining) and Begrotingsposten (tile: count with money left).
  - 🗄️ Administratie: Journaal, Rekeningen, Bezittingen (tile: count whose warranty ends within 90 days).
  - 🛒 Boodschappen: Facturen (tile: count without a linked payment), Producten (tile: count of unclassified products, the same count and list as Verwerken's Producten classificeren).
- **Beheer**, from the account menu, works like a hub with a landing page and hub column: Categorieën, Productsoorten, Gezinsleden, Groepen, and for admins only Gebruikers and the admin dashboard. Every user may open Beheer and edit categories.
- **Landing page** per hub: one tile per page. A tile with a count shows it, also when it is 0. A tile opens that page's list, filtered where the count is filtered.
- **Hub column** next to the rail on a wide screen: the hub name (linking to the landing page), then its pages, each with a badge carrying the tile's count. A count of 0 shows no badge.
- **Narrow window above phone width:** the hub column hides and the landing page takes over.
- **Phone:** the rail becomes a five-tab bar of the hubs. The landing page is the list. Search sits in the title bar. The avatar that opens the account menu sits only in the Overzicht title bar.
- **New filtered lists** behind the tiles: unclassified products, receipts without a linked payment, chattels whose warranty ends within 90 days.
- **Highlight.** The rail marks the hub that owns the current page, and the hub column marks the page, also on nested pages (show, edit, new). Verwerken owns its filtered lists. A record opened from them belongs to its own hub: a transaction lights Administratie.
- **Origin-aware back link.** A page opened from a landing tile shows "‹ <hub>" in its title bar and returns to that landing page, even when the page belongs to another hub. A record opened from that list returns to the list. The origin survives show → edit → save or cancel. After Verwijderen… the user lands on the origin landing page. Without an origin, the back link goes to the record's index page, as today.
- **Te doen** goes. Verwerken replaces it, and `/todo` redirects to the Verwerken landing page.
- **Admin** pages use the app shell. The separate admin layout goes.
- **appkit:** `_nav` becomes the shell nav (rail, hub column, account menu), fed by one menu map, with an `### Upgrading` changelog entry.

## Out of scope

- The mvpa.css work itself: rail, hub column, tile grid (their own slice) and count badges (`sheets-segmented-control-badges`).
- Segmented controls and sheets, including a "Nieuwe categorie…" sheet next to the category picker.
- The Contracten page.
- The fixes in `ui-review-bug-fixes` (labels, profile "Terug" target, accounts pager and the others).
- Renaming or moving existing resource routes.
- The dashboard's content.
- The MCP endpoint.

## Acceptance criteria

- The rail shows 🔍, Overzicht, Verwerken, Plannen, Administratie, Boodschappen and the user's name, and nothing else.
- With 12 transactions without a category, the Verwerken landing page shows a Categoriseren tile with 12, and the hub column shows a 12 badge next to Categoriseren.
- With every account classified, the Rekeningen indelen tile shows 0 and the hub column shows no badge next to it.
- Clicking the Categoriseren tile opens the journal filtered to transactions without a category, with "‹ Verwerken" in the title bar.
- Opening a transaction from that list, pressing Bewerken and then Opslaan returns to the transaction, whose back link still returns to the filtered list, which still leads back to Verwerken.
- Deleting a transaction opened from a Verwerken tile lands on the Verwerken landing page.
- A transaction opened from search shows a back link to the Journaal.
- On a transaction's edit page, the rail marks Administratie and the hub column marks Journaal.
- On a budget's show page, the rail marks Plannen and the hub column marks Budgetten.
- A chattel whose warranty ends in 60 days counts on the Bezittingen tile; one whose warranty ends in 120 days does not.
- A receipt without a linked payment counts on the Facturen tile, and the tile opens the receipts list filtered to those.
- With no active budget, the Budgetten tile says so and opens Budgetten.
- Overzicht opens the dashboard, with no hub column.
- Opening `/todo` lands on the Verwerken landing page.
- A family member who is not an admin sees Categorieën, Productsoorten, Gezinsleden and Groepen in Beheer, and no Gebruikers.
- An admin sees Gebruikers and the admin dashboard in Beheer, inside the same rail and account menu.
- At phone width, the bottom bar shows exactly the five hubs, the Overzicht title bar holds the avatar, and other title bars do not.
- In a window narrower than the hub-column width but wider than a phone, the hub column is gone and the landing page is reachable from the rail.
- No page scrolls sideways at any width.

## Flagged concerns

- This slice depends on an mvpa.css slice for the rail, hub column and tile grid that has no intent yet, and on the open `sheets-segmented-control-badges` slice for badges. Chosen side: wait for both (upstream first), so the app PR merges after them.
- Replacing appkit's `_nav` changes every app that uses appkit. Chosen side: replace it, and document the steps in appkit's `### Upgrading` entry.
- The rail highlights the owning hub, while the back link returns to the origin hub. A transaction opened from Verwerken lights Administratie and leads back to Verwerken. Chosen side: both, as decided.

## Decisions

- The hub column hides below a set width, above phone width, and the landing page takes over — recommended option chosen; replaces the 11 Oct "never hidden" remark.
- Rail, hub column and tile grid styles go upstream into mvpa.css first, in their own slice — no reason given.
- Groepen moves to Beheer, next to Gezinsleden — no reason given.
- Verwerken replaces Te doen, and `/todo` redirects there — recommended option chosen.
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
- On a phone the account avatar sits only in the Overzicht title bar — Etienne: "i do want the avatar to be only on the Overzicht page, not every header".
- appkit's `_nav` is replaced, not kept beside the new partial — no reason given.
- Approve `bundle update appkit` and `bundle update mvpa-css` up front — no reason given.
- Autonomous delivery, no Codex review — no reason given.
- The Boodschappen Producten tile counts unclassified products (no type or no brand), the same as Verwerken — recommended option chosen; one definition, one list.

## Open questions

None.
