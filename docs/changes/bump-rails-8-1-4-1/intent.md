# Intent: Make main's pre-push hooks green: Rails 8.1.4.1, two gems, rubocop

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no

## Problem

No branch can be pushed through the lefthook pre-push hook, because main fails two of its checks. `bundle exec bundler-audit check` fails: Rails 8.1.4 has advisories GHSA-2gff-2mmg-m73p (High), GHSA-2586-8ghr-69fj (Medium) and GHSA-5957-c7qm-m469 (Low), fixed in 8.1.4.1; `addressable` 2.9.0 has 7 advisories; `sqlite3` 2.10.1 has one. `bundle exec rubocop` fails with 410 offenses in 120 files, 391 of them `Style/RbsInline/MissingTypeAnnotation`, since the `92596a5` gem update. The hook runs both over the whole tree, so one fix without the other still blocks every push, and main's CI lint stays red.

## Proposed outcome

`bundler-audit check` reports no vulnerabilities, `bundle exec rubocop` reports no offenses, and every branch can be pushed again.

## Affected users and systems

All branches of this repository. `Gemfile.lock`, and the Ruby files that carry the missing signatures.

## Constraints

- Update only Rails and its own dependent gems (`bundle update rails`), then only `addressable` and `sqlite3` (`bundle lock --conservative --update addressable sqlite3`). Never `bundle update` for everything.
- Etienne approved the Rails bump on 2026-11-06 and the `addressable` and `sqlite3` updates on 2026-11-06 (playbook rule 11).
- Fix the rubocop offenses in the code. No cop is disabled, no disable comment is added, no linter config is edited.
- No behaviour change: signatures are comments, autocorrects must not change what the code does.
- No deploy files, no migrations, no system tools.

## In scope

- `Gemfile.lock` moves Rails and its sibling gems from 8.1.4 to 8.1.4.1, in one commit.
- `Gemfile.lock` moves `addressable` and `sqlite3` to their fixed versions, in a second commit.
- The 410 rubocop offenses reach zero through RBS signatures and autocorrects, in commits of one logical change each.

## Out of scope

- Any other gem update.
- Any behaviour change, unless 8.1.4.1 breaks a test.
- The MCP parity branch. It rebases on this change once it is delivered.
- Deployment. A post-deploy check of the Rails IP-spoof change is recorded in the plan, for Etienne.

## Acceptance criteria

- `bundle exec bundler-audit check` reports no vulnerabilities.
- `bundle exec rubocop` reports no offenses.
- The full test suite, system tests and Brakeman stay green.
- A branch with a clean tree passes the whole pre-push hook.

## Decisions

- Bump Rails in a change of its own, then rebase the MCP parity branch on it — chosen by Etienne ("bump rails now") after the audit blocked the push.
- Also bump `addressable` and `sqlite3` — chosen by Etienne; the audit stays red without them.
- Fix main's rubocop in the code — chosen by Etienne (rule 25); no cop disabled.
- One pull request for the bump and the rubocop fix, as separate commits — the pre-push hook needs both green in one tree, so neither can be pushed alone.

## Open questions

None.
