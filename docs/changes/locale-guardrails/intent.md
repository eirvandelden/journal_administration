# Intent: Locale guardrails

Author: Etienne van Delden de la Haije. Status: accepted (2026-10-24). Type: chore.
Delivery: autonomous
Codex review: no

## Problem

Untranslated or wrongly translated text reaches production without any check noticing.
Production falls back to English when an `nl` or `it` key is missing, and tests never raise on a missing translation.
The suite checks keys only, so a hardcoded string in a view, an English value copied into `nl` or `it`, or a dynamic key that does not exist all pass.
PR #388 (merged) already added the missing form-label keys and `<html lang>`.
After #388, 33 `nl` and 28 `it` values still equal the English text. Most are legitimate (emoji or format-only strings, cognates such as Dashboard and Status). `it` has `admin.users.form.password: Password` untranslated, and `nl` has the typo `Hoofdcategoriëen` (`categories.main`).

## Proposed outcome

A missing translation, an untranslated value, a hardcoded UI string, or a page that shows English in `nl` or `it` fails the test suite and CI before it can ship.
The locale files in `en`, `nl` and `it` are clean, so the new checks start green.

## Affected users and systems

- Dutch and Italian users, who see English text today.
- Developers, who get failing tests and a lint error instead of a silent fallback.
- `config/environments/test.rb`, `development.rb`, `test/i18n_test.rb`, `config/locales/*.yml`, `app/views`, `.herb.yml`, a new custom herb rule, and `.github/workflows/ci.yml`.

## Constraints

- No new gems or npm packages.
- Approved: editing `.github/workflows/ci.yml` (playbook rule 13), for item 7 only.
- Production keeps `fallbacks = true` as a safety net.
- Locale files stay normalized (`i18n-tasks normalize`).
- Playbook rules 8, 9, 11, 12 apply unchanged; no drops, no tool installs.

## In scope

- `config.i18n.raise_on_missing_translations = true` in test and development.
- Fallbacks off in the test environment.
- A test in `test/i18n_test.rb` that fails when an `nl` or `it` value equals the English value, with an allowlist for words identical in every language (Dashboard, Status, Email and the like).
- A custom herb-lint rule in `.herb/rules/` that flags literal text nodes and literal `placeholder`, `title`, `alt` and `aria-label` attributes in ERB. It runs as an error.
- A check that finds English strings in `flash`, `notice`, `alert` and error messages in controllers and models.
- A system test that loads the main pages in `nl` and in `it` and fails on a "translation missing" span or on known English text.
- A CI job that runs the i18n tests.
- Fix every existing violation the new checks find that #388 did not already fix: genuinely untranslated values (the legitimate identical ones go on the allowlist), hardcoded view text (moved into `en`, `nl`, `it`), English flash and error strings, and the `Hoofdcategoriëen` typo.

## Out of scope

- Model-assisted review of locale diffs (item 6). It belongs in the dotfiles `review` skill and gets its own change there.
- Form-label keys and `<html lang>`, which #388 already delivered.
- Adding new languages.
- Any change to production fallback behaviour.
- Translating data users enter, such as category names.

## Acceptance criteria

- A view that calls `t("no.such.key")` fails the test suite.
- A key that exists in `en` but whose `nl` value is still the English text fails the i18n test, unless the key or value is on the allowlist.
- An ERB file with the literal text `<p>Save</p>` fails `herb-lint`; the same file with `<%= t(".save") %>` passes.
- A controller that sets `notice = "Saved"` is reported by the English-string check.
- With the user's locale set to `nl`, the dashboard page shows no English text and no "translation missing" span; the same holds for `it`.
- A pull request that adds a missing or untranslated key fails CI.
- On `main` after this change, the full test suite, `herb-lint`, `i18n-tasks health` and RuboCop are green.
- `it.yml` shows `Password` translated, and `nl.yml` shows `Hoofdcategorieën`.

## Flagged concerns

None.

## Decisions

- One intent for items 1–5 and 7 instead of splitting — chosen by Etienne when offered the split.
- Item 6 stays out of this repository — it lives in the dotfiles `review` skill.
- Hardcoded-text check is a custom herb-lint rule, not a Minitest scan — chosen by Etienne.
- Autonomous delivery, no Codex review — chosen by Etienne.
- The `ci.yml` edit is approved for item 7 — approved by Etienne.
- Existing violations are fixed in this change so the rule is an error from day one — chosen by Etienne.
- Scope is re-measured on `main` after #388; work #388 did is not redone — Etienne pointed out #388 fixes some missing translations.

## Open questions

None.
