# Intent: Clear the bundler-audit advisories on puma and net-ssh

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore. Delivery: autonomous. Codex review: no.

## Problem

`bundle exec bundler-audit check` is red on main. puma 8.0.2 has 10 advisories. net-ssh 7.3.6 has 3, one of them High (GHSA-hjwv-j52r-xcg7). The lefthook pre-push hook refuses every push while the audit is red. The `load-defaults-8-1` review found it.

## Proposed outcome

`bundle exec bundler-audit check` reports no vulnerabilities, so pushes and CI pass again.

## Affected users and systems

- Every developer who pushes: the pre-push `bundler_audit` hook.
- The app server (puma) in every environment.
- Kamal deployment tooling (net-ssh, through kamal and sshkit).

## Constraints

- Etienne instructed the upgrade to the latest minor versions (2026-11-23). This approves the dependency change under playbook rule 11.
- puma goes to 8.1.2, the latest release and a minor bump from 8.0.2.
- net-ssh goes to 7.3.10, the latest 7.3.x release. kamal 2.12.0 pins `net-ssh ~> 7.3`, so 8.x is not installable without a kamal change. 7.3.10 clears all three advisories (fixes: `~> 7.3.8`, `~> 7.3.9`, `~> 7.3.10`).
- Approved permissions: the two gem version bumps (rule 11). Nothing else needs approval.
- Update only these two gems (`bundle update puma net-ssh`), never `bundle update` for everything.
- Branches off main, as a separate branch from `load-defaults-8-1` (playbook rule 25).

## In scope

- `Gemfile.lock` changes for puma and net-ssh, and any transitive dependency they pull in.

## Out of scope

- A net-ssh 8.x upgrade or a kamal upgrade.
- Any other gem update.
- Config changes for puma 8.1.

## Acceptance criteria

- `bundle exec bundler-audit check` reports no vulnerabilities.
- The test suite and all linters (rubocop, herb, brakeman, i18n-tasks) stay green.
- The app boots in development under puma 8.1.2 and answers `/up` with 200.

## Decisions

- Upgrade to the latest minor versions that kamal's constraint allows (puma 8.1.2, net-ssh 7.3.10) — Etienne's instruction.

## Open questions

None.
