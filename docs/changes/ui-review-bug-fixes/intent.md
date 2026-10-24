# Intent: UI review bug fixes

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-22). Type: bugfix. Delivery: autonomous. Codex review: no.

## Problem

The October 2026 UI review ([artifact](https://claude.ai/artifact/Btg62aW6itkPG4pZJiKFe6), slice 8 "clean-up") found small defects that are still present on main after #386:

- On the user list (`/users`), an administrator cannot change a user between member and administrator: ticking the role box does nothing. The markup asks for a `form` Stimulus controller that exists neither in the app nor in appkit.
- On your own profile edit page (reached from the menu), "Terug" sends you to the user list, a page the menu does not offer.
- Labels on the transaction, category and chattel forms show English attribute names (Debitor, Creditor, Category, Note, Booked at, Interest at, Type, Original note, Direction, Parent category, Purchase transaction) for a user whose locale is Dutch or Italian.
- The page has no `<html lang>`, so browsers and screen readers do not know the page language.
- The accounts index writes its pager by hand, twice per table, while `shared/_pagination` exists but only knows the `page` parameter.

## Proposed outcome

An administrator changes a role on `/users` with one click. Your own profile edit page has no misleading back link. Form labels speak the user's language. Every page declares its language. The accounts index uses the shared pager.

## Affected users and systems

- Administrators managing roles on `/users`.
- Every signed-in user on their own profile edit page.
- Users with locale `nl` or `it` on the transaction, category and chattel forms.
- Screen readers and browsers (page language).
- Views: `users/_user`, `users/profiles/edit`, `transactions/_form`, `categories/_form`, `chattels/_form`, `layouts/application` (and `layouts/admin`), `accounts/index`, `shared/_pagination`; locale files `nl.yml` and `it.yml`; a Stimulus controller for the role toggle.

## Constraints

- Binding UI rules: `rails-ui` skill, `references/interaction-design.md`.
- Every user-facing string comes from i18n; locale files stay normalized (`i18n-tasks normalize`).
- Each fix is a bug fix: its regression test comes first and fails before the fix. The pager change is a refactor: existing behaviour stays and stays tested.
- No new gems, npm packages, system tools, destructive migrations or deploy-file changes are expected; any such need is a stop-and-ask.
- Stay clear of the parallel slices: navigation-hubs (menu, navigation, menu highlighting) and sheets-segmented-control-badges in mvpa.css.

## In scope

- Role toggle on `/users`: changing the box saves the role at once. Keep the existing rules: disabled for your own row and for non-administrators.
- Remove "Terug" from your own profile edit page. Profile show keeps "Terug" to `/users`, since you reach it from there.
- Translate in `nl` and `it` every attribute name the transaction, category and chattel forms label, including the admin-only import fields and the chattel purchase transaction field.
- Set `<html lang>` to the current locale on every layout.
- Accounts index pager through the shared pagination partial, with the page parameter per table (`own_page`, `external_page`) kept.
- One pull request, one commit per fix.

## Out of scope

- The red invalid border before typing: the cause is mvpa.css `:invalid`; it goes to a later mvpa.css change.
- The parent-category field: #386 already replaced the category show form with a `<dl>`.
- Navigation, the menu and menu highlighting (navigation-hubs slice).
- Other pages' layout, the admin user edit page, and English labels outside the three forms.

## Acceptance criteria

- An administrator on `/users` ticks the role box of a member; that member is now an administrator, without pressing another button.
- An administrator on `/users` unticks the role box of another administrator; that user is now a member.
- On `/users` the role box of your own row stays disabled, and a member sees every role box disabled.
- On your own profile edit page there is no "Terug" link; Annuleren still leads to your profile.
- On another user's profile show page, "Terug" still leads to `/users`.
- A user with locale `nl` opening a transaction's edit page sees Dutch labels for debitor, creditor, category, note, booked at, interest at, type and the original import fields, not the English names.
- A user with locale `nl` sees Dutch labels for direction and parent category on the category form, and for purchase transaction on the chattel form.
- A user with locale `it` sees Italian labels for the same fields.
- A user with locale `nl` gets `<html lang="nl">`; a user with locale `en` gets `<html lang="en">`; a signed-out visitor gets the default locale.
- The accounts index shows the same previous/next links as today for own and external accounts, each paging its own table, now rendered through the shared pager.

## Decisions

- Include the role toggle, the profile Terug, the Dutch/Italian labels and `<html lang>` — chosen from the review's clean-up list after verifying each on main.
- Pager refactor in, red border out — the pager is small and in the same area; the border is an mvpa.css fix.
- One PR, one commit per fix — chosen over one PR per fix.
- Make the role toggle work, rather than remove it from `/users` — no reason given.
- Remove Terug on your own profile edit page — the menu and Annuleren are enough.
- Autonomous delivery, no Codex review — chosen at the delivery question.

## Open questions

None.
