# Intent: Run Solid Queue in async mode inside Puma

Author: Etienne van Delden. Status: accepted (2026-10-25).
Type: chore. Delivery: autonomous. Codex review: no.

## Problem

Production uses about 500 MB for this app. The Solid Queue Puma plugin forks a supervisor, a dispatcher, a scheduler and a worker. Each fork is a separate Ruby process. CT104 has 12 GB for about 12 apps, with 2 to 5 users per app, so job throughput does not matter.

## Proposed outcome

In production, Solid Queue runs its dispatcher, scheduler and worker as threads inside the Puma process. The expected saving is about 160 MB. Jobs and recurring tasks run as before.

## Affected users and systems

The production host CT104 (Kamal, single web role). Background jobs: `Importing::Ing::ImportJob`, `Appkit::SessionExpiryJob`, the finished-job cleanup. Development keeps the forked workers.

## Constraints

- solid_queue 1.7.0 supports async mode. Inside Puma, only `solid_queue_mode :async` after `plugin :solid_queue` switches it. `SOLID_QUEUE_SUPERVISOR_MODE` has no effect there.
- Async mode ignores `processes` in `config/queue.yml`.
- The threads share the queue database connection pool. The pool must cover 3 worker threads, the dispatcher, the scheduler, the supervisor heartbeat and the Puma threads that enqueue jobs.
- No deploy. Etienne deploys. No kamal commands. `config/deploy.yml` stays untouched unless the pool fix truly needs an environment variable; then ask first.
- No new gems, no migrations, no secrets read. The README recommends fork mode; Etienne chose async on purpose.

## In scope

- `config/puma.rb`: `solid_queue_mode :async` in production only.
- The queue database pool and the production primary pool in `config/database.yml`, large enough for the threads.
- Local, production-like verification with recorded evidence.

## Out of scope

- Deployment and `config/deploy.yml`.
- Changing queue names, worker thread count or polling intervals.
- Other memory work (Puma threads, SQLite pragmas, the other apps).
- Development behaviour (stays forked).

## Acceptance criteria

- With async mode on, `ps` shows one Ruby process for Puma and no solid-queue-supervisor, -dispatcher, -scheduler or -worker process.
- An enqueued job runs, and an ING CSV import job still completes.
- The recurring tasks in `config/recurring.yml` load, including `Appkit::SessionExpiryJob`.
- `/up` returns 200.
- In development, the forked processes still start and `bin/dev` still runs jobs.
- The full test suite and every linter stay green.

## Decisions

- Autonomous delivery, no Codex review — chosen by Etienne at intent time.
- Async mode in production only, not development — Etienne's choice; no reason given.
- Also raise the production primary pool, not only the queue pool — job threads share it with request threads; avoids connection timeouts (plan stage, approved 2026-10-26).

## Open questions

None.
