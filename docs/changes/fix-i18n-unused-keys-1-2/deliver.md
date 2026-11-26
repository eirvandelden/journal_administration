# Delivery account: fix-i18n-unused-keys-1-2

## Behaviour delivered

- `config/i18n-tasks.yml` sets `search.strict: false`, so keys read through dynamic keys count as used again on i18n-tasks 1.2.1. The unused-key check goes from 141 false hits to none, with no gem change.
- `Gemfile.lock` moves puma 8.0.3 to 8.1.2 and net-ssh 7.3.6 to 7.3.10 (the newest net-ssh that kamal's `~> 7.3` pin allows), so `bundler-audit check` reports no vulnerabilities.

## Evidence

- `bin/rails test`: 1698 runs, 0 failures. `test/i18n_test.rb`: 7 runs, 0 failures; `test_no_unused_keys` failed before the change.
- rubocop, herb, brakeman, `i18n-tasks normalize` and `i18n-tasks health` are green. `bundler-audit check --update`: no vulnerabilities.
- A scratch dead key is still reported as unused, and a scratch removal of `search.shortcut_hint` is still reported as missing.
- Boot in development under Puma 8.1.2: `/up` returns 200, and the Solid Queue supervisor and dispatcher start.

## Review outcome

One round, one Important finding (the branch carries the audit commits). Dismissed: Etienne decided to deliver both fixes in one pull request, and `plan.md` now covers them. Nothing else found.

## Limits

- System tests do not run locally (Capybara CDP reset error on Edge and Chrome 158, also on main). CI decides.
- Production `solid_queue_mode :async` is not exercised locally.
- `search.strict: false` also hides a future dead key under a dynamic prefix, as on i18n-tasks 1.1.2.
- The four Bundler pre-push hooks failed on the known `GIT_DIR` worktree bug and were skipped with Etienne's approval. The same checks ran directly and passed.
