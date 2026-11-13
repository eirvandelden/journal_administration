# Review: navigation-hubs

## Round 1 — 2026-11-07 08:26 UTC — 456b7ef9

Scope: phase B (`origin/main...HEAD`, 13 commits, working tree clean). No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. Checks at this SHA: `bin/rails test` green (1548 runs, 0 failures), rubocop clean, herb-lint 0 failing (12 hints, none in this diff), Brakeman no warnings, i18n-tasks normalized with no unused and no missing keys.

Compliance, acceptance criteria to proof:

- Rail shows 🔍, five hubs and the user's name only: `navigation_hubs_test.rb` "rail shows search, five hubs and the user name only".
- Categoriseren tile 12 and badge 12: `navigation_hubs_test.rb` "categoriseren tile and badge count uncategorized transactions".
- Rekeningen indelen 0 and no badge: `navigation_hubs_test.rb` "rekeningen indelen shows zero and no badge".
- Categoriseren tile opens the filtered journal with "‹ Verwerken": `origin_back_link_test.rb` "categoriseren tile opens the filtered journal with a verwerken back link".
- Show, Bewerken, Opslaan round trip: `origin_back_link_test.rb` "origin survives show edit and save".
- Delete lands on Verwerken: `origin_back_link_test.rb` "delete from a verwerken flow lands on verwerken".
- Transaction from search links back to Journaal: `origin_back_link_test.rb` "transaction without origin links back to the journal".
- Transaction edit highlights Administratie and Journaal: `navigation_hubs_test.rb` "transaction edit highlights administratie and journaal".
- Budget show highlights Plannen and Budgetten: `navigation_hubs_test.rb` "budget show highlights plannen and budgetten".
- Bezittingen 60 versus 120 days: `navigation_hubs_test.rb` "bezittingen tile counts warranties ending within 90 days".
- Facturen count and filtered list: `navigation_hubs_test.rb` "facturen tile counts and opens receipts without payment".
- Budgetten without an active budget: `navigation_hubs_test.rb` "budgetten tile without active budget".
- Begrotingsposten 1 and money-left filter: `navigation_hubs_test.rb` "begrotingsposten tile counts and opens appropriations with money left".
- Overzicht without hub column: `navigation_hubs_test.rb` "overzicht is the dashboard without hub column".
- `/todo` lands on Verwerken: `navigation_hubs_test.rb` "todo redirects to verwerken".
- Member sees Beheer without Gebruikers: `navigation_hubs_test.rb` "member sees beheer without gebruikers".
- Admin sees Gebruikers and admin dashboard in the shell: `navigation_hubs_test.rb` "admin sees gebruikers and admin dashboard in the shell".
- Phone width: five-tab bar, avatar only on Overzicht: missing (`test/system/navigation_hubs_test.rb` not written; the avatar half is covered by `navigation_hubs_test.rb` "only the overzicht title bar holds the avatar").
- Narrow window hides the hub column: missing.
- No page scrolls sideways at any width: missing for laptop and narrow width; `responsive_tables_test.rb` covers phone width only and now lists the landing pages.

Deleted tests (`todo_test.rb`, `todos_index_test.rb`, `todos_helper_test.rb`, the todo pagination test) follow the plan's deletion list; no test was weakened or skipped.

- [ ] Important: Phase C is not built, so three acceptance criteria (phone tab bar, narrow window, no sideways scroll at every width) and the Proof tests `test/system/navigation_hubs_test.rb` and `test/integration/transaction_amounts_test.rb` are missing; the plan's Implementation notes record this, but the intent says the app pull request waits for the mvpa.css rail slice, so delivery must not open the PR as complete before phase C lands — `docs/changes/navigation-hubs/plan.md:471` → fixed (Bump mvpa-css to the rail, hub column and landing tiles release)
- [ ] Important: `Gemfile.lock` bumps minitest 6.0.6 to 6.1.0 and io-console 0.9.4 to 0.9.5 in the commit "Bump appkit to the menu map and task-hub nav"; appkit depends on neither, and the intent approves only `bundle update appkit` and `bundle update mvpa-css` ("any other gem … is a stop-and-ask"), so revert these two to their `origin/main` versions or ask Etienne — `Gemfile.lock:258` → fixed (Keep minitest and io-console at main's versions)
- [ ] Important: The origin drifts from an account to its transactions: `accounts/show` renders `transactions/_table`, whose amount link goes through `menu.carry`, so an account opened from Rekeningen indelen links to `/debit/<id>?from=processing`; that transaction then shows "‹ Categoriseren" to `/transactions?filter=no_category&from=processing` (verified with a throwaway request), and deleting it lands on Verwerken; this breaks the plan's "Explicit carry" decision that a link between an account and a transaction never carries the origin — `app/views/transactions/_table.html.erb:33` → fixed (Keep the origin off an account's transaction links)
- [ ] Important: Saving a product opened from Producten classificeren redirects to `/products?from=processing` (verified), the unfiltered list, so the household loses the unclassified filter after every save; the intent says a record opened from a tile's list returns to that list, and the round-trip test checks only the back link, not the save — `app/controllers/products_controller.rb:36` → fixed (Return a saved product to the list it was opened from)
- [ ] Nit: `destroy` splits `format.html {` from its `redirect_to`, which starts at column 1 on the next line; rubocop passes, but the block reads as broken (same shape in `app/controllers/chattels_controller.rb:88`) — `app/controllers/accounts_controller.rb:97` → fixed (Write the failed-destroy redirects as do-end blocks)
- [ ] Nit: The title-bar block's closing `<% end %>` is indented two spaces, unlike every other title bar (same in `app/views/admin/users/show.html.erb:4`) — `app/views/appropriations/show.html.erb:4` → fixed (Align the title-bar end tag on the appropriation and user pages)
- [ ] Nit: `MenuMap#tile_text` and `MenuMap#carried_path` are public and not in the plan's `### Signatures`; the Implementation notes name them and both carry inline RBS, so update the Signatures block to match — `app/controllers/concerns/menu_map.rb:28` → fixed (docs: add the MenuMap helpers and the review fixes to the navigation-hubs plan)

## Round 2 — 2026-11-11 13:41 UTC — 940f654b

Scope: `origin/main...HEAD` after the rebase, with a focus on the commits since round 1 (`b5b682c1` to `940f654b`). No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. Checks at this SHA, Ruby 4.0.7: `bin/rails test` green (1665 runs, 0 failures, 0 skips); rubocop 1 offense (below); herb-lint 0 failing; Brakeman no warnings; bundler-audit no vulnerabilities; i18n-tasks normalized, no unused and no missing keys. System tests not run: they need the rail slice's CSS (round 1, finding 1).

Round 1 closures hold: `Gemfile.lock` now differs from `origin/main` only in the appkit revision; the account page passes `carry_origin: false`; a saved product returns to its tile list; both have tests.

Compliance, the criteria phase C adds:

- Phone width, five-tab bar, avatar only on Overzicht: `test/system/navigation_hubs_layout_test.rb` "phone tab bar and avatar only on overzicht" (expected red until the mvpa-css bump).
- Narrow window hides the hub column, landing page reachable from the rail: `test/system/navigation_hubs_layout_test.rb` "narrow window hides hub column and keeps landing page" (expected red until the bump). 900px sits between the rail slice's 768px and 1024px breakpoints.
- No page scrolls sideways at any width: `test/system/responsive_tables_test.rb` "no page scrolls sideways at laptop narrow or phone width" (widened from phone width only; not weakened).
- Amount link inside its `<data>`: `test/integration/transaction_amounts_test.rb` "an amount link sits inside its data element".

The system tests match the rail slice's accepted plan: the `<search>` and labelled `<summary>` copies in the title bar, `nav.rail + nav` hidden below 1024px, the rail search and account item hidden at 768px and below. No existing test was weakened, skipped or deleted in this round's commits.

- [ ] Important: rubocop fails on this line, 141 characters against the 120 limit (Layout/LineLength), introduced in "Emit the rail slice's markup for search and landing tiles"; the pre-push hook and CI rubocop go red — `test/integration/navigation_hubs_test.rb:17` → fixed (Wrap the rail search assertion to the line limit)
- [ ] Important: the charge amount on the appropriation page is still `<a><data>…</data></a>`; mvpa.css #45 draws every `a data` as a count pill and hides `value="0"`, and its Upgrading step 5 says to check every `<data>` inside a link, but phase C moved only the journal and recent-transactions amounts; after the bump the charges table shows pills, and the amount-link test does not cover this page — `app/views/appropriations/show.html.erb:37` → fixed (Put the charge amount link inside its data element)
- [ ] Nit: `assert_select "a data", count: 0` runs over the whole page, so it also asserts that the hub column shows no badge; on the journal and account pages that holds only because no fixture chattel's warranty ends within 90 days. Scope it to the table. The `text: /0,00/` match also passes for "10,00", so it does not prove the zero amount — `test/integration/transaction_amounts_test.rb:66` → fixed (Check only main for amount pills and pin the zero amount's text)
- [ ] Nit: Proof names `test/integration/hub_queries_test.rb` for both query-count tests; they live in `navigation_hubs_test.rb` instead, and the Plannen test compares two runs rather than pinning the measured number as Complexity asks; the Implementation notes record neither departure — `test/integration/navigation_hubs_test.rb:178` → fixed (Move the hub query counts to their own test and pin the Plannen count)
- [ ] Nit: `list_path` reaches through `menu.back` into the returned link's `path` (Law of Demeter); appkit already answers a path directly with `exit_path`, so a similar `Menu` method, or a note on why the chain stays, keeps the controller to one call — `app/controllers/products_controller.rb:59` → dismissed: `Appkit::Menu::Link` is a value object, so reading its `path` does not reach through a collaborator; the title bar reads `back_link.path` the same way, and a `Menu#back_path` needs a separate appkit release outside this change

## Round 3 — 2026-11-11 13:49 UTC — a016a9c4

Scope: `origin/main...HEAD`, with a focus on the four fix commits since round 2 (`0c2a5695` to `a016a9c4`). No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. Checks at this SHA, Ruby 4.0.7: `bin/rails test` green (1666 runs, 0 failures, 0 skips); `hub_queries_test.rb` green alone with seeds 1, 2 and 3; rubocop clean (468 files); herb-lint 0 failing (12 hints, none in this diff). Brakeman, bundler-audit and i18n-tasks not re-run: the fix commits touch no Gemfile, locale or controller. System tests not run: they need the rail slice's CSS (round 1, finding 1).

Round 2 closures hold:

- The rail search assertion now wraps under 120 characters; rubocop passes on the file.
- The appropriation page renders `<data value><a>amount</a></data>`; "a charge amount link sits inside its data element" in `appropriations_test.rb` checks the link and that `main` holds no `a data`. No other view in `app/views` still wraps a `<data>` in a link.
- `transaction_amounts_test.rb` scopes the pill check to `main`, and `/\A\D*0,00\z/` rejects "10,00".
- `test/integration/hub_queries_test.rb` now holds both query tests named in Proof, with `assert_queries_match` and `assert_queries_count`; the Plannen landing page is pinned at 18 queries with 1 and with 10 charged appropriations. The budget fixtures are dated relative to today, so the pinned count does not drift with the date. `navigation_hubs_test.rb` still uses `AppropriationPayments` (`credit`), so its include stays needed.
- The `ProductsController#list_path` Law of Demeter dismissal holds: `Appkit::Menu::Link` holds only `label` and `path` with no behaviour, so `menu.back(…)&.path` reads a value, not a collaborator's collaborator; `_title_bar` reads `back_link.path` the same way.

Compliance: every Proof line maps to a test as in round 2; the system test file name departs from Proof and the Implementation notes record it. No test was weakened, skipped or deleted in this round's commits; the two query tests moved, and both now assert more than before.

Design: no new public method; no new call chain, N+1 loop or glossary `Avoid:` word in this round's diff.

Nothing new found. Round 1's phase C finding stays open until the mvpa.css rail slice merges and mvpa-css is bumped.

## Round 4 — 2026-11-11 20:08 UTC — c3b4ff9a

Scope: `origin/main...HEAD` (`e157f367`), with a focus on the rebase onto main and the four commits since round 3 (`45467239` to `c3b4ff9a`). No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. Checks at this SHA, Ruby 4.0.7: `bin/rails test` green (1667 runs, 0 failures, 0 skips); `bin/rails test:system` green (35 runs, 0 failures), now against the bumped mvpa.css; rubocop clean (468 files); herb-lint 0 failing (12 hints, none in `hubs/show`); Brakeman no warnings; bundler-audit no vulnerabilities; i18n-tasks normalize leaves the tree unchanged.

Rebase: `git range-diff` against `a016a9c4` shows one changed commit, "Navigate by task hubs", which now also deletes main's `test/controllers/todos_controller_page_test.rb` (#413). That test covers only `TodosController::Page`, which the branch deletes, and the Implementation notes record the removal. #413's other changes (the `Todo::Item` YARD types, the packing slip test) touch no other file of this branch.

`Gemfile.lock` against `origin/main` changes only the appkit and mvpa-css revisions, as the intent approves; minitest stays at 6.0.6.

mvpa.css Upgrading steps from 2026-10-25 to 2026-11-11, checked against the app at this SHA:

- 2026-11-11 step 1: the rail has `class="rail"`; appkit `d106f6b` still emits `class="hub-column"` (see the Nit below). No mvpa.css rule selects `.hub-column` (grep over the installed gem), so the class does not change the layout.
- Steps 2 and 3: the rail's search is a `<search>` as the nav block's first output; `_title_bar` puts `<search>` as a direct child of `main > header nav`.
- Step 4: the Overzicht title-bar `<summary>` has `aria-label` set to the user's name (`avatar: true`); the system test checks it.
- Step 5: appkit's `_nav` sets `aria-current="true"` on the hub and `"page"` on the page.
- Step 6: `hubs/show` renders `main > nav > ul` with no `class="tiles"`, and writes the count as text, not as `<data>`.
- Step 7: `<html lang="<%= I18n.locale %>">` in the application layout.
- Step 8: no rail, hub column or tile rules in `app/assets/stylesheets/local`. Step 9 does not apply (the app imports `mvpa/mvpa.css`).
- 2026-11-03: no `week-navigation` in the app. 2026-10-26: the local CSS gives `body > header` no paint and no `min-block-size`. 2026-10-25: no `<menu>` in `app/views`; every remaining `<data>` next to a link wraps the link (`transactions/_table`, `shared/_recent_transactions`, `appropriations/show`); `title_bar.css` and its `@import` are gone; no view switch sits in a title bar.

Compliance: every acceptance criterion maps to its test as in rounds 1 to 3; the phone, narrow-window and no-sideways-scroll criteria now pass against the merged CSS (`navigation_hubs_layout_test.rb` "phone tab bar and avatar only on overzicht", "narrow window hides hub column and keeps landing page"; `responsive_tables_test.rb` "no page scrolls sideways at laptop narrow or phone width"). The new test "a tile shows its label above its text at every width" covers the tile layout fix at laptop and phone width. No test was weakened or skipped; the one deleted test covers deleted code.

Design: no new public method, call chain, N+1 loop or glossary `Avoid:` word in this round's diff.

- [ ] Nit: mvpa.css 2026-11-11 Upgrading step 1 says to remove `class="hub-column"`; the Implementation notes leave this to "a follow-up" in appkit, but neither appkit nor this plan tracks one (no appkit issue or pull request mentions `hub-column`). Open an appkit issue, or name the follow-up in the notes, so the step does not get lost — `docs/changes/navigation-hubs/plan.md:481` → fixed (docs: name the appkit hub-column follow-up in the navigation-hubs plan)
- [ ] Nit: Phase C Order of work step 2 asks for a check of the form errors in the dark themes, since the 2026-11-06 release darkens the surfaces; the notes say the error state was not captured, so the check is open. `form_errors.css` also gives a disabled input `--color-bg`, the page colour, which in the dark themes is now lighter than the surface around it. Look at one form with an error and one disabled input in `solunized-dark`, and record the result — `docs/changes/navigation-hubs/plan.md:484` → fixed (docs: record the dark-theme form error check in the navigation-hubs plan)

## Round 5 — 2026-11-11 20:13 UTC — 9dfb7297

Scope: `origin/main...HEAD` (`e157f367`), with a focus on the two docs commits since round 4 (`5874d977`, `9dfb7297`). Both touch only `plan.md`; no code, test, Gemfile or locale changed, so round 4's checks still apply (1667 runs, 35 system runs, rubocop, herb-lint, Brakeman, bundler-audit, i18n-tasks all clean). Re-run here, Ruby 4.0.7: `navigation_hubs_test.rb`, `main_navigation_test.rb` and `hub_queries_test.rb` green (27 runs, 0 failures). `Gemfile.lock` still differs from `origin/main` only in the appkit and mvpa-css revisions.

Round 4 closures hold:

- Dark-theme form errors: the solunized-dark screenshot shows the red "Bedrag" label and the red border on its input, and the disabled ID, Debiteur and Crediteur inputs with dimmed text on a lighter fill. The computed styles agree in all three themes: `.field_with_errors` label and input border take `--color-danger`; `input:disabled` takes the body colour (L 0.33 in dark, 0.24 in black), lighter than the article surface (L 0.27, 0.18), with opacity 0.6. The note in `plan.md` matches this.
- appkit hub-column follow-up: the note names the file (`app/views/appkit/shared/_nav.html.erb`, line 17 at `d106f6b` emits the class) and the `bundle update appkit` step. No CSS rule in mvpa-css `6e4fc63` selects `.hub-column`; only its changelog test names it. Not opening an appkit issue is right under playbook rule 6.

Compliance: every acceptance criterion maps to its test as in round 4; no test was weakened, skipped or deleted since round 4.

Design: no new public method, call chain, N+1 loop or glossary `Avoid:` word since round 4.

- [ ] Nit: the follow-up says to drop `class="hub-column"` in appkit and then run `bundle update appkit`, but eight assertions in this app select `nav.hub-column` (`test/integration/navigation_hubs_test.rb:32`, 43, 51, 58, 115, 170; `test/integration/main_navigation_test.rb:45`, 46), so that bump turns them red. Name them in the note, so the follow-up switches them to `nav.rail + nav`, the selector mvpa.css uses — `docs/changes/navigation-hubs/plan.md:481` → fixed (Find the hub column as the nav after the rail in the navigation tests)

## Round 6 — 2026-11-11 20:17 UTC — ee1c31fb

Scope: `origin/main...HEAD` (`e157f367`), with a focus on the two commits since round 5 (`b2aeb524`, `ee1c31fb`). Since round 4 only `plan.md` and the two navigation tests changed (`git diff --stat c3b4ff9a..HEAD -- . ':!docs'`), so round 4's full-suite and linter results still apply. Re-run here, Ruby 4.0.7: `navigation_hubs_test.rb`, `main_navigation_test.rb` and `hub_queries_test.rb` green (27 runs, 91 assertions, 0 failures); rubocop clean on both test files.

Round 5 closure holds:

- All eight assertions now select `nav.rail + nav`, the selector mvpa-css `6e4fc63` uses (`16_rail.css:202`, `body > header > nav.rail + nav`). appkit `d106f6b` `_nav.html.erb` renders the hub column as the element right after `nav.rail`, so the selector does not depend on `class="hub-column"`. No `hub-column` selector is left in `app`, `test`, `config` or `lib`; the remaining mentions are in the plan's design history and the follow-up note.
- The note at `plan.md:481` now says that the appkit bump needs no test change, which matches the tests.
- The positive assertions still prove the hub column: `navigation_hubs_test.rb:32` (badge `<data>`), 51, 58 and 170 (`aria-current="page"`), and `main_navigation_test.rb:45`, 46 (Beheer links) each need a match.
- `navigation_hubs_test.rb:115` (`nav.rail + nav`, 0 on Overzicht): the same test asserts `nav.rail` exists, and the partial puts the hub column right after the rail whenever it renders, so 0 matches means no hub column. It proves the criterion.
- `navigation_hubs_test.rb:43` (`count: 0` for `<data>` in the Rekeningen indelen link): see the Nit. The rename did not change its strength; the gap was there with `nav.hub-column` too.

Compliance: every acceptance criterion maps to its test as in round 4. No test was weakened, skipped or deleted; the eight assertions changed only their selector, to one that matches the same element.

Design: no new public method, call chain, N+1 loop or glossary `Avoid:` word since round 5.

- [ ] Nit: "rekeningen indelen shows zero and no badge" asserts only that no `<data>` sits in a hub-column link to `accounts_path(filter: :untouched)`; nothing in the test asserts that the link is there. If the menu map changes that page's path or the hub column does not render, the `count: 0` passes with no match and the zero-badge criterion goes unproven. Assert the link first (`nav.rail + nav a[href=?]`, count 1), then the absent `<data>` — `test/integration/navigation_hubs_test.rb:43` → fixed (Anchor the zero-badge check on the Rekeningen indelen hub-column link)

## Round 7 — 2026-11-11 20:21 UTC — a555e3da

Scope: `origin/main...HEAD` (`e157f367`), with a focus on the one commit since round 6 (`a555e3da`). Since round 4 only `plan.md` and the two navigation tests changed (`git diff --stat c3b4ff9a..HEAD -- . ':!docs'`), so round 4's full-suite and linter results still apply. Re-run here, Ruby 4.0.7: `navigation_hubs_test.rb`, `main_navigation_test.rb` and `hub_queries_test.rb` green (27 runs, 92 assertions, 0 failures); `test/system/navigation_hubs_layout_test.rb` green (3 runs, 13 assertions); rubocop clean (468 files).

Round 6 closure holds:

- "rekeningen indelen shows zero and no badge" now asserts `nav.rail + nav a[href=?]` to `accounts_path(filter: :untouched)` with count 1 before the `data` count 0. appkit `d106f6b` `_nav.html.erb` renders the `<data>` only when the count is positive, so the pair proves that the link is there and carries no badge.

The zero-count and `assert_no_selector` assertions the branch adds or changes in `test` (`git diff origin/main...HEAD -- test`), checked one by one:

- Anchored by a positive assertion on the same container in the same test: `appropriations_test.rb` `main a data` (the `data > a` charge link); `transaction_amounts_test.rb` `main a data` (the `td data > a` amount link); `origin_back_link_test.rb` `tbody a[href*='from=']` (the `tbody` transaction link); `navigation_hubs_test.rb:44` (line 43), `:116` (`nav.rail` and its `aria-current`), `:132` (the four other `main > nav` tiles; `:142` finds the same href for the admin); `main_navigation_test.rb:36` (`nav.rail details` profile and Beheer links); `navigation_hubs_layout_test.rb:27` (`main > header nav > search > button` on line 28).
- The five show-page `main input[name=_method][value=delete]` checks (accounts, categories, chattels, groups, people) narrow a whole-page check to `main`. appkit's account menu now puts a `button_to … method: :delete` sign-out form in the rail, so the narrowing is needed; the record's own delete form would render inside `main`, so the checks keep their strength.
- Not anchored: `navigation_hubs_layout_test.rb:21`, `:29` and `:36` (see the Nit).

The deleted negatives (`main_navigation_test.rb` Filters and Todo summaries, `main_navigation_menus_test.rb` Filters, the todo page tests) cover the todo menu and page, which the branch deletes.

Compliance: every acceptance criterion maps to its test as in round 4. No test was weakened, skipped or deleted since round 6; the commit adds one assertion.

Design: no new public method, call chain, N+1 loop or glossary `Avoid:` word since round 6.

- [ ] Nit: the phone and narrow-window tests prove the hidden hub column and rail search only with `assert_no_selector "body > header > nav.rail + nav"` and `assert_no_selector "nav.rail > search"`, and nothing in those tests shows the element is in the page. The integration tests prove `nav.rail + nav` and `nav.rail > search` exist, but not the `body > header >` part. If the layout wraps or moves `<header>`, mvpa.css `body > header > nav.rail + nav` stops hiding the column and these checks still pass. Assert the element with `visible: :hidden` instead, so each check needs a match and proves it is hidden (also lines 29 and 36) — `test/system/navigation_hubs_layout_test.rb:21` → fixed (Prove the rail search and hub column are rendered but hidden)

## Round 8 — 2026-11-11 20:23 UTC — dca5bc03

Scope: `origin/main...HEAD` (`e157f367`), with a focus on the one commit since round 7 (`dca5bc03`). Since round 4 only `plan.md` and three test files changed (`git diff --stat c3b4ff9a..HEAD -- . ':!docs'`), so round 4's full-suite and linter results still apply. Re-run here, Ruby 4.0.7: `test/system/navigation_hubs_layout_test.rb` green (3 runs, 13 assertions); `navigation_hubs_test.rb`, `main_navigation_test.rb` and `hub_queries_test.rb` green (27 runs, 92 assertions); rubocop clean (468 files).

Round 7 closure holds:

- Lines 21, 29 and 36 now use `assert_selector …, visible: :hidden`, so each check needs the element in the page and needs it hidden. mvpa-css `6e4fc63` hides both with `display: none`: `body > header > nav.rail + nav` below 1024px, `nav.rail > search` at 768px and below. The phone width (390) and the narrow width (900) fall inside those ranges. At laptop width the hub column shows, so the same assertion would fail there; the check is not vacuous.
- Line 27 (`assert_no_selector "main > header nav details", visible: :all`) stays as it is. Line 28 proves `main > header nav` on the same hub page, and line 23 proves the `details` selector matches on Overzicht. The zero match therefore means that the hub title bar renders no account menu.

Compliance: every acceptance criterion maps to its test as in round 4. No test was weakened, skipped or deleted since round 7; the commit makes three assertions stricter.

Design: no new public method, call chain, N+1 loop or glossary `Avoid:` word since round 7.

Nothing new found.

## Round 9 — 2026-11-13 09:41 UTC — 0ddaca60

Scope: `origin/main...HEAD` (merge base `e157f367`, the current `origin/main`), with a focus on the ten commits since `187efa59` (phases E1 and E2), against the intent amended on 2026-11-11 and the plan's "Amendment of 2026-11-11: phases D and E". Working tree clean. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. Checks at this SHA, Ruby 4.0.7: `bin/rails test` green (1696 runs, 0 failures, 0 skips); `bin/rails test:system` green (37 runs, 0 failures); rubocop clean (475 files); herb-lint 0 failing (12 hints); Brakeman no warnings; bundler-audit no vulnerabilities; i18n-tasks normalize leaves the tree unchanged, no unused and no missing keys.

`Gemfile.lock` against `origin/main` changes only the appkit and mvpa-css revisions. appkit `42e22b3` is the head of appkit `main` (`git ls-remote`), so phase D merged before the bump, as the intent requires.

Compliance, the amended acceptance criteria to proof:

- Rail shows 🔍, five hubs and 👤 Profiel, no pop-up: `navigation_hubs_test.rb` "rail shows search, five hubs and profiel" (see the Nit on its file).
- Consolideren tile and badge 12: `navigation_hubs_test.rb` "consolideren tile and badge count transactions to consolidate".
- € 100 split 60 / 40 counts and lists: `navigation_hubs_test.rb` "partly split transaction counts on consolideren".
- Rekeningen indelen 0 and no badge: `navigation_hubs_test.rb` "rekeningen indelen shows zero and no badge".
- Consolideren tile opens the filtered journal with "‹ Verwerken": `origin_back_link_test.rb` "consolideren tile opens the filtered journal with a verwerken back link".
- Show, Bewerken, Opslaan round trip; delete lands on Verwerken; search origin; edit and budget highlight; Bezittingen; Facturen; Budgetten; Begrotingsposten; Overzicht: unchanged since round 4.
- Verwerken hub column order: `navigation_hubs_test.rb` "verwerken hub column order".
- Importeren tile, item and title-bar action: `navigation_hubs_test.rb` "importeren tile item and title bar action"; `main_navigation_menus_test.rb` clicks the title-bar action.
- Alles tile 4 and list newest first: `navigation_hubs_test.rb` "alles tile counts and lists every open item".
- `/todo` shows Alles in Verwerken: `navigation_hubs_test.rb` "todo shows alles in verwerken".
- Profiel landing and hub column: `navigation_hubs_test.rb` "profiel landing and hub column".
- Uitloggen signs out from tile and hub column: `navigation_hubs_layout_test.rb` "uitloggen tile signs out", "uitloggen hub column item signs out".
- Rail marks Profiel on Voorkeuren, Beheer and Categorieën: `navigation_hubs_test.rb` "rail marks profiel on voorkeuren and beheer".
- Member and admin Beheer: `navigation_hubs_test.rb` "member sees beheer without gebruikers", "admin sees gebruikers and admin dashboard in the shell", now asserting the Profiel rail mark.
- Phone: six tabs, no avatar: `navigation_hubs_layout_test.rb` "phone tab bar has six tabs and no avatar"; `navigation_hubs_test.rb` "no title bar holds an avatar".
- Narrow window: unchanged since round 4. No sideways scroll: `responsive_tables_test.rb`, now with the Profiel landing page and `/todo`.

Every other test that the amended `## Proof` names exists: `hub_queries_test.rb` "verwerken counts run once per request" (still three `SELECT COUNT` with Alles and Importeren), "profiel landing runs no count query", "alles query count is bounded by the page" (25, then 40 open transactions, pinned at 49); `origin_back_link_test.rb` "record opened from alles returns to alles"; `searches_test.rb` "search does not offer uitloggen". The appkit Proof lines live in the appkit repository.

Changed and deleted tests in these commits: the avatar, account-menu and `/todo` redirect tests give way to the amended criteria; the three `show_upload_form?` tests go with the method, as Design decisions say; the two restored `todos_index_test.rb` link assertions expect `from=processing.all`, as Design decisions say. `signing_in_test.rb` and `main_navigation_menus_test.rb` change as the Implementation notes record. None is weakened or skipped.

Design: the new `MenuMap` methods (`profile_hub`, `profile_details_pages`, `processing_open_pages`) are private and carry RBS; `Todo`, `TodosController` and `TodosHelper` differ from `origin/main` only in comments, the `Account.untouched` scope, the removed upload prompt and `menu.carry_list`, so they add no public method. No new call chain. The per-row `uncategorized_amount` read on Alles is the bounded cost that Complexity accepts and the Alles query test pins; it does not contradict a `Query count:` line. `carry_list` writes `from=processing.all` also without an origin, unlike the plan's Signatures text; the Implementation notes record that.

- [ ] Important: saving Gegevens drops the origin. The Profiel tile opens `/users/<id>/profile/edit?from=profile` with "‹ Profiel", and the form posts `from=profile`, but `update` redirects to `user_profile_path(@user)` without `menu.carry`, so the show page loses "‹ Profiel" and shows only "Terug" to `/users` (verified with a throwaway request). Cancel keeps the origin. The intent says the origin survives show → edit → save or cancel for a page opened from a landing tile, and Gegevens became a tile in this phase. Carry the origin in the redirect with a round-trip test, or record the departure in the Implementation notes — `app/controllers/users/profiles_controller.rb:30` → fixed (Keep the Profiel origin after saving Gegevens)
- [ ] Nit: Proof names `test/integration/main_navigation_test.rb` `test_rail_shows_search_five_hubs_and_profiel`, but the test lives in `test/integration/navigation_hubs_test.rb`, and the Implementation notes do not record the move. Update the Proof line or the note — `docs/changes/navigation-hubs/plan.md:704` → fixed (docs: point the rail and phone Proof lines at their tests)
- [ ] Nit: Gegevens owns the whole `users/profiles` controller, so another user's profile page (`user_profile_path(other)`, linked from `users/_user`) marks Profiel in the rail and Gegevens in the hub column, as if it were the signed-in user's own page — `app/controllers/concerns/menu_map.rb:61` → dismissed: appkit places a request by controller and filter, never by record, so own and other profiles cannot differ without a new appkit change; only an admin reaches another profile, from Beheer, and the rail then rightly marks Profiel, the parent hub of Beheer
- [ ] Nit: the glossary lists "tab" under `Avoid:` for Hub; the test name "phone tab bar has six tabs and no avatar" calls the hubs tabs. "tab bar" is the glossary's word for the phone rail, so "phone tab bar has six hubs and no avatar" says the same with the agreed word; the Proof line names the test, so it changes too — `test/system/navigation_hubs_layout_test.rb:16` → fixed (Name the phone bar items hubs in the six-item test)
