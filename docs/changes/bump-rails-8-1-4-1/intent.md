# Intent: Bump Rails to 8.1.4.1

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no

## Problem

`bundle exec bundler-audit check` fails on main: Rails 8.1.4 has advisories GHSA-2gff-2mmg-m73p (High), GHSA-2586-8ghr-69fj (Medium) and GHSA-5957-c7qm-m469 (Low), fixed in 8.1.4.1. The pre-push hook runs bundler-audit, so no branch can be pushed.

## Proposed outcome

`bundler-audit check` reports no vulnerabilities, and every branch can be pushed again.

## Affected users and systems

All branches of this repository. `Gemfile.lock` only.

## Constraints

- Update only Rails and its own dependent gems (`bundle update rails`), never `bundle update` for everything.
- Etienne approved the Rails patch bump on 2026-11-06 (playbook rule 11).
- No deploy files, no migrations, no system tools.

## In scope

- `Gemfile.lock` moves Rails and its sibling gems from 8.1.4 to 8.1.4.1.

## Out of scope

- Fixing main's rubocop offenses.
- Any other gem update.
- Any code change, unless 8.1.4.1 breaks a test.

## Acceptance criteria

- `bundle exec bundler-audit check` reports no vulnerabilities.
- The full test suite and Brakeman stay green.

## Decisions

- Bump Rails in its own change and pull request, then rebase the MCP parity branch on it — chosen by Etienne ("bump rails now") after the audit blocked the push.

## Open questions

None.
