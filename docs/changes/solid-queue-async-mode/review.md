# Review: Run Solid Queue in async mode inside Puma

## Round 1 — 2026-10-26T08:49Z — 97e7c25

No REVIEW.md or REVIEW.local.md at the repository root; the reviewer's default passes ran. Suite green (1347 runs, 0 failures), RuboCop, Brakeman and Bundler Audit clean.

Reviewer checks, by loading `config/puma.rb` through `Puma::Configuration`: production with `SOLID_QUEUE_IN_PUMA=true` loads the plugin with mode `:async`; production with `false` or unset loads no Solid Queue plugin and raises no `NoMethodError`; development and no `RAILS_ENV` load the plugin with the default fork mode. Production pools resolve to primary 8 and queue 20 (13 and 25 with `RAILS_MAX_THREADS=10`); cache and cable stay at 5. `SolidQueue.supervisor_pidfile` is unset, so the supervisor writes no pidfile with Puma's PID.

Compliance (acceptance criterion → proof):

- One Ruby process, no forked solid-queue-* process → missing (no recorded `ps`/`pgrep` output).
- An enqueued job runs; an ING CSV import job completes → missing.
- Recurring tasks load, including `Appkit::SessionExpiryJob` → missing.
- `/up` returns 200 → missing.
- Development still forks and `bin/dev` runs jobs → partly: the Puma config check above shows fork mode; no recorded run.
- Full test suite and linters green → proved by this round's run.

- [x] Important: The plan's `## Proof` checks (production-like boot `ps`/`pgrep`, queued ING import, recurring tasks, `/up`, pool log free of `ConnectionTimeoutError`, clean shutdown, development fork check) have no recorded evidence anywhere; plan step 3 and playbook §7a require the commands and output to be recorded, and configuration has no tests to stand in for them — `docs/changes/solid-queue-async-mode/plan.md:158` → fixed (docs: record evidence for solid-queue-async-mode)
- [x] Nit: `ENV.fetch("RAILS_ENV", "development")` now appears three times in this file (lines 14, 51, 55); one local such as `rails_env` would keep the environment checks in one place — `config/puma.rb:55` → fixed (config(jobs): name the Rails environment once in puma.rb)

## Round 2 — 2026-10-26T09:30Z — f725d59

No REVIEW.md or REVIEW.local.md at the repository root; the reviewer's default passes ran. Both round 1 findings are fixed and verified.

Reviewer checks: `config/puma.rb` loaded through `Puma::Configuration` after the `rails_env` refactor. Production with `SOLID_QUEUE_IN_PUMA=true` loads the plugin with mode `:async`. Production with `false` or unset loads only `tmp_restart`, with no mode and no `NoMethodError`. Development loads the plugin with no mode (fork). Test with `true` forks, as before. Production pools resolve to primary 8, cache 5, queue 20, cable 5, and to 13, 10, 25, 10 with `RAILS_MAX_THREADS=10`. RuboCop is clean on `config/puma.rb`.

Compliance (acceptance criterion → proof):

- One Ruby process, no forked solid-queue-* process → proved (`evidence.md`: `pgrep -lP` empty; all four `SolidQueue::Process` rows carry the Puma pid).
- An enqueued job runs; an ING CSV import job completes → proved (`evidence.md`: `perform_later` finished, 0 failed executions, 1 transaction).
- Recurring tasks load, including `Appkit::SessionExpiryJob` → proved (`evidence.md`).
- `/up` returns 200 → proved (`evidence.md`).
- Development still forks and `bin/dev` runs jobs → proved (`evidence.md`; this round's Puma config check). No scheduler forks in development: `config/recurring.yml` has no `development` key, and solid_queue 1.7.0 `Configuration#schedulers` returns no scheduler without recurring tasks. That is expected; the plan's Proof line named a scheduler in error.
- Full test suite and linters green → proved (`evidence.md`: 1347 and 30 runs, 0 failures; linters clean).

No open findings.

Outside this change, for a separate branch: `evidence.md` reports that `db/cable_schema.rb` on main keeps indexes on removed columns, so a fresh `db:prepare` fails. Playbook rule 25 applies if this breaks CI or a fresh deploy.
