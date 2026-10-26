# Evidence: Run Solid Queue in async mode inside Puma

Recorded from the implement stage's run (commit 97e7c25, production-like boot on port 3011) and the review fix round (config load per environment after the `rails_env` refactor).

## Production-like boot (`RAILS_ENV=production SOLID_QUEUE_IN_PUMA=true`, worktree `bin/` first on `PATH`)

- Puma pid 76377, RSS about 45 MB at idle. `pgrep -lP 76377` printed nothing: no forked solid-queue process.
- `SolidQueue::Process` listed Supervisor (async), Dispatcher, Worker and Scheduler, all with pid 76377.
- `curl http://127.0.0.1:3011/up` returned `200`.
- `SolidQueue::RecurringTask` held `clear_solid_queue_finished_jobs` and `appkit_session_expiry` (`Appkit::SessionExpiryJob`).
- `Importing::ING::ImportJob.perform_later` with `test/fixtures/files/test_import.csv` row 1: `finished_at` set, 0 failed executions, 1 transaction.
- Production pools: primary 8, cache 5, queue 20, cable 5. The boot log had no "Solid Queue needs at least" line and no `ActiveRecord::ConnectionTimeoutError`.
- `kill -INT`: "Supervisor terminated gracefully"; `SolidQueue::Process.count` was 0 afterwards.
- `SOLID_QUEUE_IN_PUMA=false`: server boots, `/up` 200, `SolidQueue::Process.count` 0.

## Development

- `bin/dev` showed a fork supervisor with dispatcher and worker children. `Appkit::SessionExpiryJob.perform_later` finished.

## Puma config after the review fix (`Puma::Configuration` loading `config/puma.rb`)

- production, `SOLID_QUEUE_IN_PUMA=true`: `solid_queue_mode` is `:async`.
- production, `SOLID_QUEUE_IN_PUMA=false`: no mode set, no `NoMethodError`.
- development, variable unset: no mode set (fork).

## Checks

- `bin/rails test`: 1347 runs, 0 failures. `bin/rails test:system`: 30 runs, 0 failures.
- rubocop, brakeman, bundler-audit, herb, `i18n-tasks normalize` (no diff): clean.

## Outside this change

- `db/cable_schema.rb` on main is broken (commit 0026a36 removed `channel_hash` and `created_at` but kept their indexes): a fresh `db:prepare` fails with `no such column: "channel_hash"`. Not fixed here.
