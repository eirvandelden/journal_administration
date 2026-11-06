# Intent: Bump gems with open security advisories

Author: Etienne van Delden. Status: accepted (2026-11-06). Type: chore. Delivery: autonomous. Codex review: no

## Problem

Bundler Audit fails on `origin/main`: Rails 8.1.4 gems, rack, nokogiri, loofah, rails-html-sanitizer, addressable and sqlite3 have published advisories. The pre-push hook runs Bundler Audit, so no branch can push.

## Proposed outcome

`bundle exec bundler-audit check` passes, and the app behaves as before.

## Affected users and systems

Every branch of this repository, through the pre-push hook. Production gets patched gems when this ships.

## Constraints

- Patch bumps only, inside the current minor versions. Never skip a major version.
- Update only the gems named by the advisories, with `bundle update <gem>`, never a full `bundle update`.
- No gem is added or removed. No `Gemfile` constraint changes unless an advisory fix needs one.

## In scope

- `Gemfile.lock` bumps for: rails 8.1.4 gems to 8.1.4.1 or newer, rack to 3.2.8 or newer, nokogiri to 1.19.5 or newer, loofah to 2.25.3 or newer, rails-html-sanitizer to 1.7.2 or newer, addressable to 2.9.1 or newer, sqlite3 to 2.10.2 or newer.

## Out of scope

- Any other gem, Ruby, Rails minor or major upgrade, `config.load_defaults`.
- Deploy files.

## Acceptance criteria

- Bundler Audit reports no vulnerabilities.
- The full test suite, system tests, rubocop, herb and brakeman pass.
- The `Gemfile.lock` diff holds only the gems above and their direct dependencies.

## Decisions

- Bump Rails now, on its own branch — "bump rails now", chosen so the account-page branch stays free of lockfile changes (playbook rule 25).

## Open questions

None.
