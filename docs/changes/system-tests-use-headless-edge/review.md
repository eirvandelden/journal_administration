# Review: system-tests-use-headless-edge

## Round 1 — 2026-10-19T14:38Z — af1e42e (codex)

No findings. Codex ran 1054 non-system tests: 0 failures, including the eight driver tests. It could not verify the system flows: headless Edge failed to start inside its sandbox.

## Round 2 — 2026-10-19T14:41Z — af1e42e (claude)

No findings. No `REVIEW.md` or `REVIEW.local.md` exists at the repository root, so the Bugs, Security and Compliance passes used the intent, the plan and the playbook.

- Bugs: Rails 8.1 `Driver` registers no driver for a non-`:selenium` name and only sets `Capybara.current_driver`, so the `:headless_edge` registration owns the options and the window size. Rails' parallel-safe driver preload does not run for it; the 17 system tests stay under the default parallel threshold of 50, so they run in one process.
- Security: test-only change; `EDGE_BIN` is read only in the test case. No secrets, no new dependency.
- Compliance: the diff matches the plan's files and design; `test/system` is unchanged; no Chrome cache lookup remains.
- Evidence: `test/application_system_test_case_test.rb` 8 runs, 0 failures; `test/system/search_dialog_test.rb` 2 runs, 0 failures; `bin/rails db:test:prepare test:system` 17 runs, 36 assertions, 0 failures, 0 errors, 0 skips; `EDGE_BIN=/nonexistent/msedge` fails with "Browser path does not exist: /nonexistent/msedge"; rubocop clean on both files.
- Open proof item: the CI `system-test` job on Edge is not yet verified. It runs after the push.

## Round 3 — 2026-10-20T07:53Z — 09d8b43 (codex)

No findings. Codex ran 1057 non-system tests: 0 failures. It could not verify the browser flows: headless Edge failed to start inside its sandbox. CI run 39273732572 passed `ci / system-test` on Edge.

## Round 4 — 2026-10-20T08:10Z — 09d8b43 (claude)

No findings. No `REVIEW.md` or `REVIEW.local.md` exists at the repository root, so the Bugs, Security and Compliance passes used the intent, the plan and the playbook.

- Bugs: the CI flags apply only when `ENV["CI"]` is present, so the local run keeps the sandbox. Each CI flag has a logged cause: f90f14d (Edge exited at start, run 39271281652) and 09d8b43 (session creation hung, run 39272222316).
- Security: test-only change. `--no-sandbox` runs only on the disposable CI runner. No secrets, no new dependency, no `.github/workflows` edit.
- Compliance: the diff matches plan steps 1–9; `test/system` is unchanged; no Chrome cache lookup remains. Step 9's failing-test-first rule holds: each CI flag has a unit test.
- Evidence: `test/application_system_test_case_test.rb` 11 runs, 28 assertions, 0 failures, with and without `CI=1`; rubocop clean on both files; CI run 39273732572 passed every job, and `ci / system-test` logged 17 runs, 36 assertions, 0 failures, 0 errors, 0 skips on Edge.
