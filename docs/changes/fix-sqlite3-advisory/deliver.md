# Delivery account: fix-sqlite3-advisory

## Behaviour delivered

The app runs on `sqlite3` 2.10.2 in place of 2.10.1. Advisory GHSA-4fqr-96q8-xrfx (Medium, SQL query truncation for strings of 4 GiB or larger) no longer applies. `Gemfile.lock` is the only changed file outside the change folder: the ten `sqlite3` platform entries and their ten checksums.

## Evidence

- `bundle exec ruby -e 'require "sqlite3"; puts SQLite3::VERSION'` prints `2.10.2`.
- `RAILS_ENV=test bin/rails runner` boots the app and reads fixtures through the new driver: `users=3 categories=13 transactions=19`, SQLite 3.54.1.
- Lockfile guard: `Gemfile` unchanged; `Gemfile.lock` numstat `20 20`; every changed line matches `sqlite3 (2.10.`; `mini_portile2 (2.8.9)` and `BUNDLED WITH 4.0.22` unchanged.

## Check results

- Bundler Audit (database refreshed): no `sqlite3` advisory. The other gems still fail; `bump-rails-security-advisories` covers them.
- Brakeman: exit 0, no warnings.
- Herb: exit 0.
- RuboCop: 391 offenses on the branch and 391 on `main`. No new offense; the existing ones belong to `fix-rbs-inline-offenses`.
- `bin/rails test`: 1494 runs, 4430 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rails test:system`: 32 runs, 173 assertions, 0 failures, 0 errors, 0 skips.

## Review outcome

Round 1 (Claude reviewer, `00fb4e43`): no Important or Nit findings. Codex review was not enabled.

## Deviations, approved by Etienne

- The push ran with all hooks off (`LEFTHOOK=0`, later `--no-verify`). Inside `git push`, git sets `GIT_DIR`, and Bundler then fails on the appkit git gem, so the Brakeman and test hooks cannot run. Every check above ran by hand on the same tree. Another agent fixes that hook bug.
- The pull request's `ci / lint` (RbsInline offenses) and `ci / scan_ruby` (other gem advisories) jobs are expected to be red. Both failures exist on `main`.
- During implementation, another session moved the shared bundler git checkouts for appkit and mvpa.css to other revisions. Claude waited until they were back on the locked revisions and did not touch them.
