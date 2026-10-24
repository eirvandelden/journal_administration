## Round 1 — 2026-10-24 07:16 UTC — dd6a3fc

Reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (clean at review start). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes.

- [ ] Nit: The host login layout is not the verbatim appkit copy the plan names. Appkit writes `<html <%= tag.attributes(theme_attributes) %> data-controller="theme">`; the copy writes four explicit `data-*` attributes. A signed-out visitor has an empty `theme_attributes`, so the page now carries `data-color-scheme=""`, `data-light-theme=""`, `data-dark-theme=""` and `data-theme=""` where appkit wrote none. The empty `data-theme` stops mvpa.css's `@media (prefers-color-scheme: dark) :root:not([data-theme])` button and header-link rules from matching until the theme controller connects, so a dark-OS visitor gets light buttons on first paint (and for good with JavaScript off). Keep appkit's `tag.attributes(theme_attributes)` and add only `lang`. — `app/views/layouts/login.html.erb:2` → fixed (Leave out empty theme attributes on the signed-out login page)
- [ ] Nit: Removing the Terug link leaves an empty `render layout: "shared/title_bar" ... do %><% end %>` block, which adds a new herb `erb-no-empty-control-flow` hint (below the fail level). It is the only title bar in the app without controls. — `app/views/users/profiles/edit.html.erb:2` → fixed (Render the profile edit title bar without an empty block)

### Validation

- `bin/rails test`: 1332 runs, 3990 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rails test:system`: 30 runs, 119 assertions, 0 failures, 0 errors, 0 skips (includes `test/system/user_roles_test.rb`, 2 runs green).
- RuboCop: 381 files, no offenses. Herb: exit 0 (hints only). ESLint `app/javascript`: exit 0.
- Brakeman: no warnings. Bundler audit: no vulnerabilities. `i18n-tasks normalize`: no diff.

### Bugs and security

- `submit-on-change` calls `requestSubmit()`, so Turbo sends the form's `_method=patch`; a disabled role box fires no `change`. `UsersController#update` still runs `ensure_can_administer`, so the client-side `disabled` is not the only guard.
- `shared/_pagination`'s `param` defaults to `:page`; `request.query_parameters` is indifferent-access, so the merge replaces the string key as before. The twelve other render sites pass no `param` and render unchanged links.
- No new queries; no new user input reaches SQL, HTML or redirects.

### Compliance

| Acceptance criterion | Proving test |
| --- | --- |
| Admin ticks a member's role box; member becomes administrator, no other button | `test/system/user_roles_test.rb`: "an administrator makes a member an administrator by ticking the role box" |
| Admin unticks another admin's role box; that user becomes a member | `test/system/user_roles_test.rb`: "an administrator makes another administrator a member by unticking the role box" |
| Own role box disabled; a member sees every role box disabled | `test/integration/users_index_test.rb`: "your own role box is disabled", "a member sees every role box disabled" |
| Own profile edit page has no Terug; Annuleren leads to your profile | `test/integration/users/profiles_test.rb`: "your own profile edit page has no back link", existing "the edit form ends in an action row of Annuleren and Opslaan" |
| Another user's profile show page keeps Terug to `/users` | `test/integration/users/profiles_test.rb`: "another user's profile page links back to the users list" |
| nl transaction edit labels | `test/integration/form_labels_test.rb`: "the transaction form labels its fields in Dutch" |
| nl category direction/parent and chattel purchase transaction labels | `test/integration/form_labels_test.rb`: "the category form labels direction and parent category in Dutch", "the chattel form labels the purchase transaction in Dutch" |
| it labels for the same fields | `test/integration/form_labels_test.rb`: the three "… in Italian" tests |
| `<html lang>` nl / en / signed-out default | `test/integration/page_language_test.rb`: "a Dutch user gets lang nl", "an English user gets lang en", "the admin layout declares the user's language", "a signed-out visitor gets the default locale" |
| Accounts index pagers unchanged, each paging its own table, through the shared pager | `test/integration/pagination_navigation_test.rb`: existing "accounts pagination shows correct links on first and last page", new "external accounts pagination writes external_page", "accounts pagination keeps the other query parameters"; `test/integration/accounts_index_test.rb`: existing "own and external pagination params are independent" |

Every test named in `plan.md`'s `## Proof` exists, including the `param` default invariant tests and `test/i18n_test.rb`'s `test_no_missing_keys` and `test_files_are_normalized`. No existing test was weakened, skipped or deleted; the diff only adds tests.

### Design

- No new Ruby methods, so no RBS signatures are due; the one new JS method, `submit()`, is the one `### Signatures` names.
- No Law of Demeter chains, no N+1 loops, and no glossary `Avoid:` word in names, comments or tests.
- The five fixes land as five commits in the plan's order.

## Round 2 — 2026-10-24 07:21 UTC — 5a0299a

Re-reviewed `git diff origin/main...HEAD` after fetching origin, plus the working tree (only `review.md` untracked). No root `REVIEW.md` or `REVIEW.local.md` exists; used the default Bugs, Security, Compliance and Design passes. Focus: the two fix commits for the Round 1 nits.

No findings.

### Validation

- `bin/rails test`: 1333 runs, 3994 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rails test:system`: 30 runs, 119 assertions, 0 failures, 0 errors, 0 skips.
- RuboCop: 382 files, no offenses. Herb: exit 0; `users/profiles/edit` and `layouts/login` are clean, so the `erb-no-empty-control-flow` hint is gone. ESLint `app/javascript`: exit 0.
- Brakeman: no warnings. Bundler audit: no vulnerabilities. `i18n-tasks normalize`: no diff.

### Round 1 fixes

- `layouts/login` now writes `tag.html(lang: I18n.locale, **theme_attributes, "data-controller": "theme")`. Like appkit's `tag.attributes(theme_attributes)`, it writes no attribute for an empty hash or a nil value, so a signed-out page carries no `data-theme` and mvpa.css's `:root:not([data-theme])` dark rules match again. `test/integration/login_layout_test.rb` proves it: no `data-theme`, no `data-color-scheme`, `data-controller="theme"` kept. `test/integration/page_language_test.rb` still proves `lang` on that layout.
- `users/profiles/edit` renders `shared/title_bar` as a plain partial, the same form `dashboard/index`, `receipts/index` and `admin/dashboard/index` use; `controls` is blank, so no `<nav>` renders. "your own profile edit page has no back link" and the Annuleren action-row test stay green.

### Bugs, security, compliance, design

- No change since Round 1 outside the two fixes; Round 1's bug, security and compliance notes and its acceptance-criterion table still hold.
- The two fixes add no queries, no user input and no Ruby methods.
