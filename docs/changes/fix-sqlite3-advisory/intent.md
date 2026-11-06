# Intent: Fix the sqlite3 security advisory

Author: Etienne van Delden. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no

## Problem

Bundler Audit flags `sqlite3` 2.10.1 with advisory GHSA-4fqr-96q8-xrfx (Medium): a SQL query string of 4 GiB or larger can be silently truncated. The fix is in 2.10.2.

## Proposed outcome

The app runs on `sqlite3` 2.10.2 or newer, and Bundler Audit no longer reports GHSA-4fqr-96q8-xrfx. The app behaves as before.

## Affected users and systems

Every environment that uses the SQLite database: development, test, CI and production. `Gemfile.lock` only.

## Constraints

- Update only `sqlite3`, with `bundle update sqlite3`, never a full `bundle update`.
- Patch bump inside 2.10. No `Gemfile` constraint change: `>= 2.0` already allows 2.10.2.
- No gem is added or removed. No deploy files, migrations or system tools.
- Permissions approved: the `sqlite3` patch bump only (playbook rule 11). Nothing under rules 8, 9, 12 or 13.
- Pushing skips only the pre-push `bundler_audit` command (`LEFTHOOK_EXCLUDE=bundler_audit`). Before that push, Claude runs rubocop, herb, Brakeman and the tests by hand, and confirms Bundler Audit reports no `sqlite3` advisory.

## In scope

- `Gemfile.lock` moves every `sqlite3` platform entry and checksum from 2.10.1 to 2.10.2 or newer.

## Out of scope

- The other gems with advisories (Rails 8.1.4 gems, rack, nokogiri, loofah, rails-html-sanitizer, addressable). `bump-rails-security-advisories` and `bump-rails-8-1-4-1` cover them.
- Open Dependabot pull requests.
- Any code change, unless 2.10.2 breaks a test.

## Acceptance criteria

- Bundler Audit reports no `sqlite3` advisory.
- The `Gemfile.lock` diff holds only `sqlite3` lines.
- The full test suite, system tests, rubocop, herb and Brakeman stay green.
- The branch reaches `origin` while the other gems still fail Bundler Audit.

## Decisions

- Fix sqlite3 in its own change and merge it first; `bump-rails-security-advisories` then no longer needs its sqlite3 bump — Etienne: "if we merge this first it closes, just do what i said".
- Push with only the pre-push audit hook skipped — chosen so this change can merge first; CI never runs Bundler Audit, so only this one local check is skipped.
- Deliver autonomously, no Codex review — chosen because a one-gem patch bump needs no second reviewer; same mode as the sibling advisory changes.

## Open questions

None.
