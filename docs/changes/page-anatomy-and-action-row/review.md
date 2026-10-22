# Review: page-anatomy-and-action-row

## Round 1 — 2026-10-22 11:24 UTC — a1185d2

Checks: `bin/rails test` 1214 runs, 0 failures; `bin/rails test:system` 27 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `i18n-tasks missing` clean, `normalize` left no diff. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran.

Compliance: every acceptance criterion in `intent.md` maps to its `plan.md` Proof test, and all 45 named tests exist in the diff. The two manual VoiceOver or accessibility-tree checks are for the pull request. Removed or rewritten tests each follow a behaviour the intent changes (Delete moved off show pages, no action columns, no ID columns, no truncation, native confirm). No test was skipped or weakened.

- [x] Nit: After a rejected save, the delete confirm names the unsaved value. Example: clear a person's name, save, then press `Verwijderen…`; the confirm reads `"" verwijderen?`. Use the stored name (`attribute_in_database(:name)`, or `to_s` on the persisted state) in the people, groups, accounts, categories and chattels forms. — `app/views/people/_form.html.erb:15` → fixed (Name the stored value in the delete confirm after a rejected save)
- [x] Nit: `todos.index.actions`, `classify`, `edit` and `update_transactions` have no caller now that the action column is gone. They stay in all three locales, but plan step 9 removes keys the change leaves unused. `i18n-tasks unused` misses them because of the dynamic `t(".#{item.kind}")`. — `config/locales/nl.yml:797` → fixed (Remove the todos.index keys the action column left unused)
- [x] Nit: `Budget#to_s` is a new public model method that `plan.md` does not name; the plan says "partials only". It has a YARD `@return` and a test, so this needs only a line in the plan's Design decisions, or a move into the views. — `app/models/budget.rb:35` → fixed (docs: record Budget#to_s in the plan's App design decisions)
- [x] Nit: The chattel show page renders `notes` as plain text in a `dd`, so line breaks the old read-only textarea kept now collapse into one line. — `app/views/chattels/show.html.erb:8` → fixed (Keep the line breaks in the chattel notes on the show page)

## Round 2 — 2026-10-22 11:35 UTC — 69315fe

Checks: `bin/rails test` 1220 runs, 0 failures; `bin/rails test:system` 28 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `i18n-tasks missing` clean, `normalize` left no diff. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. This round reads the five commits since `a1185d2`; the round 1 fixes each hold and have a test.

Compliance: no test was removed, skipped or weakened. The new `title_bar.css` has a system test (`a long single-word title wraps instead of scrolling sideways at phone width`).

- [x] Nit: The title-bar heading wrap rule is a new app stylesheet that `plan.md` does not name. The intent sends the title-bar layout (`main > header`) upstream to mvpa.css. Move the rule into the upstream title-bar row layout, or record the app-side rule and its reason in the plan's design decisions. — `app/assets/stylesheets/local/layout/title_bar.css:2` → fixed (docs: record the title-bar heading wrap rule in the plan's App design decisions)
- [x] Nit: The account form's confirm repeats the name-or-number fallback of `Account#to_s` on the stored attributes. If `to_s` changes, the confirm and the rest of the app name the account differently. — `app/views/accounts/_form.html.erb:29` → fixed (Share the account label fallback between to_s and the delete confirm)

## Round 3 — 2026-10-22 11:43 UTC — 2c677af

Checks: `bin/rails test` 1222 runs, 0 failures; `bin/rails test:system` 28 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `i18n-tasks missing` clean. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. This round reads the two commits since `69315fe`; the round 2 fixes each hold, and `Account#stored_label` has two model tests.

Compliance: no test was removed, skipped or weakened. Bugs and Security: `to_s` keeps its old behaviour (`name.presence || account_number`), and the confirm text still goes through `t` and Turbo's `data-turbo-confirm`, so it stays escaped.

- [ ] Nit: `Account#stored_label` is a new public model method that `plan.md` does not name; the plan says "partials only". Round 1 closed the same gap for `Budget#to_s` with a line in the App design decisions. Add one for `stored_label`, or keep the fallback in the view. — `app/models/account.rb:109` → fixed (docs: record Account#stored_label in the plan's App design decisions)

## Round 4 — 2026-10-22 11:46 UTC — e18c0ea

Checks: `bin/rails test` 1222 runs, 0 failures; `bin/rails test:system` 28 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `i18n-tasks missing` clean. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. This round reads the one commit since `2c677af` and the branch against the freshly fetched `origin/main`. The round 3 fix holds: `plan.md` App design decisions now name `Account#stored_label`.

Compliance: no test was removed, skipped or weakened. The checks above ran on the branch as it stands, not rebased, so they do not cover the conflict below.

- [x] Important: The branch is 27 commits behind `origin/main`. PR #385 (`multiple-account-numbers-per-account`, merged 2026-10-22) moves numbers into `account_numbers` and adds `self.ignored_columns += [ "account_number" ]` to `Account`. After the rebase that playbook rule 20 requires, `stored_label` calls `account_number_in_database` and the form renders `f.text_field :account_number`. Neither attribute exists on an ignored column, so the account edit page raises. `to_s` on main is now `name`, else `numbers.min.to_s`, so the shared `label_from` fallback no longer matches it. Twelve files overlap: `accounts_controller.rb`, `account.rb`, the account `_form`, `index` and `show` views, `shared/_recent_transactions`, `transactions/_table`, the three locales, `accounts_index_test.rb` and `account_test.rb`. Rebase onto `origin/main`. Rebuild `stored_label` on the persisted `account_numbers`, then keep main's number fieldset inside the new form anatomy. Re-run the suite. — `app/models/account.rb:110` → fixed (Read the account label fallback lazily and prove the delete confirm on account_numbers)
- [x] Important: PR #385 adds a page that this change's intent covers: "every page has an `h1` in a shared title bar", and a show page's commands follow the reference. `accounts/merges/new` hand-rolls a `<header>` with `h1` and an `Annuleren` link in a `nav`, instead of using `shared/_title_bar`. After the rebase, give it the shared title bar. Add it to the `page_headings_test.rb` coverage, so the "every page" criterion still holds. — `app/views/accounts/merges/new.html.erb:2` (on `origin/main`) → fixed (Give the account merge page the shared title bar)

## Round 5 — 2026-10-22 12:00 UTC — d0755db

Checks: `bin/rails test` 1310 runs, 0 failures; `bin/rails test:system` 28 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `i18n-tasks missing` clean. `i18n-tasks unused` lists only keys that main already leaves unused (`budgets.destroy.confirm`, `transaction_splits.*.success` and others); this branch adds none. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. This round reads the five commits since `e18c0ea` and the branch rebased on the freshly fetched `origin/main` (`f082b1c`, which contains #385).

The round 4 fixes hold. `to_s` and `stored_label` read `account_numbers`, and the number fallback runs only when the name is blank. `numbers.compact.min` keeps the blank number row that `edit` builds from breaking the title. The account form keeps main's number fieldset inside the shared errors and action row. The duplicate-number tests now expect the shared alert. `accounts/merges/new` uses the shared title bar and is in `page_headings_test.rb`. Its merge button and the show page's merge link are account commands, which slice 6 handles.

Compliance: every acceptance criterion still maps to its `plan.md` Proof test. No test was skipped or weakened; the removed account show tests follow the moved Delete, and `accounts_edit_test.rb` covers the refused delete.

- [ ] Nit: `assert_select "th", text: I18n.t("accounts.index.id"), count: 0` can never fail. This change removes `accounts.index.id`, so `I18n.t` returns a "Translation missing" string that no header shows. `index_pages_test.rb` already proves the criterion with a literal `Id` pattern. Drop the line, or match the literal header text. — `test/integration/accounts_index_test.rb:110` → fixed (Match the literal Id header in the accounts index no-ID-column test)
- [ ] Nit: Removing the "destroy redirects back with alert" test left two blank lines between two tests. — `test/integration/accounts_show_test.rb:110` → fixed (Remove a stray blank line between accounts show tests)

## Round 6 — 2026-10-22 12:05 UTC — 881abbc

Checks: `bin/rails test` 1310 runs, 0 failures; `bin/rails test:system` 28 runs, 0 failures; rubocop, herb-lint and Brakeman clean; `bundler-audit` finds no vulnerabilities; `i18n-tasks missing` clean, `normalize` left no diff. No `REVIEW.md` in the repository, so the default Bugs, Security, Compliance and Design passes ran. This round reads the two commits since `d0755db`, on the freshly fetched `origin/main`; the branch has no commits to catch up.

The round 5 fixes hold. The accounts index test now matches a literal `Id` or `ID` header, so it fails if an ID column comes back. The stray blank line in `accounts_show_test.rb` is gone. Both commits change tests only.

Compliance: no test was removed, skipped or weakened. Every acceptance criterion still maps to its `plan.md` Proof test.

Nothing found.
