# Review: locale-guardrails

## Round 1 — 2026-10-26T13:39Z — 589527f

No REVIEW.md or REVIEW.local.md at the repository root; the reviewer's default passes (Bugs, Security, Compliance, Design) apply. Checks at 589527f: `bin/rails test` 1371 runs, 0 failures; `bundle exec rubocop` 386 files, no offenses; `herb-lint app/views/` no failing offense; `i18n-tasks health` green; `i18n-tasks normalize` leaves no diff.

Compliance (intent acceptance criteria → proof):

- `t("no.such.key")` fails the suite → `test/i18n_test.rb` `test_missing_key_in_view_raises`.
- An `nl` value equal to English fails unless allowlisted → `test_allowlist_exempts_identical_values`, `test_no_untranslated_values`.
- `<p>Save</p>` fails herb-lint, `t(".save")` passes → `test/lib/herb/locale_no_literal_text_test.rb` (all 8 plan cases present).
- `notice = "Saved"` is reported → `test/lib/rubocop/cop/locale/literal_message_test.rb` (all 11 plan cases present).
- `nl` and `it` pages show no English and no missing span → `test/system/locale_pages_test.rb`, both tests.
- A missing or untranslated key fails CI → the `i18n` job runs `i18n-tasks health` and `test/i18n_test.rb`.
- `Password` translated in `it.yml`, `Hoofdcategorieën` in `nl.yml` → present.
- `Transaction` type error localized → `test/models/transaction_test.rb` "type error is localized in Dutch".
- No existing test was skipped or deleted. Five tests that read keys missing on `main` now read real keys or literals; each assertion is now stronger, not weaker.

- [ ] Important: `main_nav.*` under `ignore_eq_base.all` exempts the whole nav subtree, which holds real words (`groups`, `people`, `preferences`, `profile`, `admin`, `todo_all`, `todo_consolidatable_*`, `todo_upload`). A new nav key with its English value copied into `nl` or `it` passes `test_no_untranslated_values`, which breaks invariant 2 and the plan's rule "a wildcard only on format-only subtrees". Only the nine `%{model}` keys (`accounts`, `appropriations`, `budgets`, `categories`, `chattels`, `product_types`, `products`, `receipts`, `todo`) are equal today; list those instead — `config/i18n-tasks.yml:166` → fixed (Allowlist only the equal main_nav keys and drop the dead locale entry)
- [ ] Nit: `users.profiles.edit.locale_{en,it,nl}` stays on `ignore_eq_base`, but this change deletes those keys; the entry is dead — `config/i18n-tasks.yml:179` → fixed (Allowlist only the equal main_nav keys and drop the dead locale entry)
- [ ] Nit: the cop misses `flash.now.alert = "..."` and `flash.now.notice = "..."`: `flash_writer?` matches only a bare `flash` receiver. Verified with `rubocop --only Locale/LiteralMessage --stdin`: `flash.now.alert = "Nope"` gives no offense. Accept `{(send nil? :flash) (send (send nil? :flash) :now)}` as the receiver, as `flash_index_assignment?` already does, with a test — `lib/rubocop/cop/locale/literal_message.rb:19` → fixed (Report flash.now notice and alert writers and keep cop matchers private)
- [ ] Nit: the three `def_node_matcher`s sit above `private`, so they are public methods; plan `### Signatures` says they stay private. In `errors_add?`, the `(send nil? :errors)` branch is redundant, because `(send _ :errors)` already matches a nil receiver — `lib/rubocop/cop/locale/literal_message.rb:14` → fixed (Report flash.now notice and alert writers and keep cop matchers private)
- [ ] Nit: `CHROME` uses `label:not(:has(select))` where the plan says `label`; the departure is sound (it keeps option text, which is user data, out of the search) but is not recorded under `## Departures` — `test/system/locale_pages_test.rb:7` → fixed (Record the system test selector departure in the plan)

## Round 2 — 2026-10-26T14:12Z — 1f44293

No REVIEW.md or REVIEW.local.md at the repository root; the default passes (Bugs, Security, Compliance, Design) apply. Checks at 1f44293: `CI=1 bin/rails test` 1372 runs, 0 failures; `bin/rails test test/system/locale_pages_test.rb test/lib` 27 runs, 0 failures; `bundle exec rubocop` 386 files, no offenses; `herb-lint app/views/` no failing offense; `i18n-tasks health` green; `i18n-tasks normalize` leaves no diff. The appkit `test` job runs `npm ci`, so the herb rule test finds `node_modules` on CI.

Round 1 fixes: the `main_nav` allowlist now lists the nine equal keys only; the dead `users.profiles.edit.locale_*` entry is gone; `flash.now.alert =` is reported and tested; the redundant `errors` branch is gone; the `CHROME` departure is recorded. Security pass: no finding. Design pass: no finding.

- [ ] Nit: the round 1 visibility fix did not take effect. `def_node_matcher` defines its method through `class_eval` with a string, which ignores the preceding bare `private`. `LiteralMessage.public_instance_methods(false)` still lists `errors_add?`, `flash_index_assignment?` and `flash_writer?`. Make them private explicitly (`private :flash_index_assignment?, :flash_writer?, :errors_add?` after the matchers), or record under `## Departures` that they stay public — `lib/rubocop/cop/locale/literal_message.rb:35` → fixed (Make the cop matchers private explicitly)
- [ ] Nit: the Italian admin user form now shows "Parola d'accesso" directly above "Conferma password" (`admin.users.form.password_confirmation`), and the profile page says "Cambia password". One form uses two words for one field. Use one term: translate the confirmation and placeholder the same way, or keep "Password" and put `admin.users.form.password` on the `it:` allowlist, as the plan's departure already offers Etienne — `config/locales/it.yml:320` → fixed (Use one Italian word for the password fields)

## Round 3 — 2026-10-26T14:40Z — f9a2861

No REVIEW.md or REVIEW.local.md at the repository root; the default passes (Bugs, Security, Compliance, Design) apply. Checks at f9a2861: `CI=1 bin/rails test` 1372 runs, 0 failures; `bin/rails test test/system/locale_pages_test.rb test/lib` 27 runs, 0 failures; `bundle exec rubocop` 386 files, no offenses; `herb-lint app/views/` no failing offense; `i18n-tasks health` green; `i18n-tasks normalize` leaves no diff; `brakeman` no warnings; `bundler-audit` no vulnerabilities.

Round 2 fixes: `LiteralMessage.public_instance_methods(false)` now lists only `on_send`, `on_pair`, `on_lvasgn` and `on_ivasgn`; the three matchers are private, and `report`, `literal_with_letter?` and `literal_text` stay private. The cop still reports `flash.now.alert = "Nope"`, `notice: "Saved"` and `errors.add(:base, "Bad")`. `it.yml` now uses "parola d'accesso" for the password label, its confirmation and the profile placeholder; no other Italian value says "password".

Bugs pass: no finding. Security pass: no finding. Compliance pass: every acceptance criterion keeps its proof from round 1. Design pass: no finding.

No open finding.
