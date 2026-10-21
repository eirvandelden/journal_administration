# Plan: Run system tests on headless Edge

From `intent.md` (2026-10-19). Status: accepted.

## Context

`test/application_system_test_case.rb` drives `:headless_chrome` and points `options.binary` at the newest Chrome for Testing build in Selenium Manager's cache (`~/.cache/selenium/chrome`, or `$SE_CACHE_PATH/chrome`), with a `CHROME_BIN` override. The cached Chrome (150) and the ChromeDriver Selenium Manager resolves (155) no longer match, so 16 of 17 system tests cannot start. `test/application_system_test_case_test.rb` holds four unit tests for that cache lookup (`ApplicationSystemTestCase.chrome_binary`).

Facts checked while planning (2026-10-19):

- Rails 8.1.4 `ActionDispatch::SystemTesting::Browser` knows only `:chrome`, `:headless_chrome`, `:firefox` and `:headless_firefox`. With `using: :edge` it builds no options object, yields `nil` to the `driven_by` block, and drops any `options:` passed in. So `driven_by :selenium, using: :edge` cannot run headless.
- A scratch spike (scratchpad copy of the test case, loaded through `RUBYOPT=-I<dir>`, worktree untouched) registered a Capybara driver for `:edge` with `--headless` and ran `bin/rails db:test:prepare test:system`: Edge 155.0.4283.62 started headless, Selenium Manager fetched `msedgedriver` into `~/.cache/selenium/msedgedriver`, and all 17 runs passed with 36 assertions, 0 failures, 0 errors, 0 skips.
- The CI system-test job is the reusable `eirvandelden/appkit/.github/workflows/rails-ci.yml@main` on `ubuntu-latest`. The Ubuntu 24.04 runner image ships Microsoft Edge 155.0.4283.45 and Microsoft Edge WebDriver 155.0.4283.45. Selenium Manager finds both, so CI needs no workflow edit.
- `README.md` and `AGENTS.md` (which `CLAUDE.md` links to) do not name Chrome or the system tests.

## Design decisions

- Register a Capybara driver named `:headless_edge` in `ApplicationSystemTestCase` and select it with `driven_by :headless_edge`. Rails' `Driver` does not register a non-`:selenium` name itself; it only sets `Capybara.current_driver`, so the registration block owns the window size. This is the smallest change that gives headless Edge without patching Rails.
- Build the options in a public class method `ApplicationSystemTestCase.edge_options(binary: ENV["EDGE_BIN"].presence)`. It returns a `Selenium::WebDriver::Edge::Options` with `--headless`, and sets `binary` only when one is given. A class method keeps the override unit-testable without starting a browser, and matches how `chrome_binary` is tested today.
- The override variable is `EDGE_BIN`, the Edge counterpart of `CHROME_BIN`. `CHROME_BIN` is no longer read.
- Keep the screen size at 1400 by 1400 in a `SCREEN_SIZE` constant, applied with `driver.browser.manage.window.size` — what Rails' own `register_selenium` does.
- Build the driver in a public class method `ApplicationSystemTestCase.edge_driver(app, driver_class: Capybara::Selenium::Driver, options: edge_options)`. It calls `driver_class.new(app, browser: :edge, options: options)` and sets the window to `SCREEN_SIZE`. The registration block is only `Capybara.register_driver(:headless_edge) { |app| edge_driver(app) }`. Injecting `driver_class` lets a unit test pass a fake driver and prove the browser, the options and the window size without starting Edge. Minitest 6 ships no `stub`, so injection is also the only way short of a new gem.
- Pass only `--headless`. Rails adds `--disable-search-engine-choice-screen` for Chrome and `--disable-gpu` on Windows; the spike passed without either on macOS, and CI runs Linux. Add nothing the run does not need.
- Delete `CHROME_CACHE_ROOT`, `CHROME_LEAF_PATHS`, `chrome_binary`, `version_dirs_newest_first`, `chrome_leaf_in` and their four unit tests. Edge comes from the system install; Selenium Manager resolves the driver.
- Add one line to `AGENTS.md` `## Commands` naming `bin/rails test:system`, headless Edge and `EDGE_BIN`. No file names Chrome today, so there is nothing to replace, but without the line the override is undiscoverable. This is the only notes edit.

## Integration points

- Capybara (`Capybara.register_driver`, `Capybara::Selenium::Driver`) and `selenium-webdriver` 4.48.0 (`Selenium::WebDriver::Edge::Options`, Selenium Manager). Both are already in the `test` group; no new gem.
- Selenium Manager downloads `msedgedriver` into its own cache on first run, which the intent allows.
- CI: the appkit reusable workflow's `system-test` job runs `bin/rails db:test:prepare test:system` on `ubuntu-latest`, which has Edge and Edge WebDriver installed. `.github/workflows/ci.yml` does not change.
- `sign_in_as` uses `page.driver.browser.manage.add_cookie`, which Edge's WebDriver supports (proved by the spike).

## Files that change

- `test/application_system_test_case.rb` — replace the Chrome for Testing lookup and `driven_by :selenium, using: :headless_chrome` with `SCREEN_SIZE`, `self.edge_options`, `self.edge_driver`, `Capybara.register_driver :headless_edge` and `driven_by :headless_edge`. `sign_in_as`, `locale` and `signed_cookie_value` stay as they are.
- `test/application_system_test_case_test.rb` — replace the four `chrome_binary` tests with the `edge_options` and driver tests named under Proof. Drop the `tmpdir` require and the `make_cached_chrome` helper.
- `AGENTS.md` — one line under `## Commands` (`CLAUDE.md` is a symlink to it).

## Order of work

1. Rewrite `test/application_system_test_case_test.rb` with the new unit tests. Run `bin/rails test test/application_system_test_case_test.rb` and watch each fail (`edge_options` undefined, driver name `:selenium`).
2. Change `test/application_system_test_case.rb`: add `SCREEN_SIZE`, `self.edge_options` and `self.edge_driver`, register `:headless_edge`, switch `driven_by`, delete the Chrome cache constants and methods. Run the unit test file until green.
3. Run one system test file first: `bin/rails test test/system/search_dialog_test.rb`. Then the whole suite: `bin/rails db:test:prepare test:system`. Every run must pass with 0 skips.
4. Check the override by hand: `EDGE_BIN=/nonexistent/msedge bin/rails test test/system/search_dialog_test.rb` must error on that binary path. Then `EDGE_BIN="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" bin/rails test test/system/search_dialog_test.rb` must pass.
5. Check the cache lookup is gone: `grep -nE "cache/selenium|SE_CACHE_PATH|CHROME" test/application_system_test_case.rb test/application_system_test_case_test.rb` prints nothing.
6. Add the `AGENTS.md` line.
7. Run `bin/rails test`, `bundle exec rubocop`, `bundle exec brakeman --no-pager -q` and `bundle exec bundler-audit check`. All green.
8. Push and confirm the CI `system-test` job passes on Edge. Its log must show the run, and no step may be skipped.
9. CI fix after delivery (change request, coordinator): the CI `system-test` job on PR #350 failed in every system test with `SessionNotCreatedError: session not created: Chrome instance exited` at `edge_driver`. Failed run: https://github.com/eirvandelden/journal_administration/actions/runs/39271281652 (job 118123921619). Find the cause from the job log and the runner image, not by guessing; the likely candidate is the Chromium sandbox on the Linux runner, fixed with Edge options such as `--no-sandbox` and `--disable-dev-shm-usage` set only when `ENV["CI"]` is present, so the local run stays unchanged. Write a failing unit test for the options first. No `.github/workflows` edit unless the log proves it is required (approved only then, see intent). After three failed CI attempts at this problem, stop and report.
10. Intermittent hang on CI (change request, coordinator, Etienne chose evidence first): after step 9 the CI `system-test` job passed once (run 39273732572) and failed twice on identical code (run 39390165356, attempts 1 and 2). Each failure is one random test with `Net::ReadTimeout` and 16 of 17 passing. Do not guess at more browser flags. First gather evidence on CI: under `ENV["CI"]` enable the Selenium debug logger and the msedgedriver log file, and write both into `tmp/screenshots/` because the existing CI artifact upload already collects that folder (no `.github/workflows` edit). Push, let CI fail or pass, and read the artifact. Then fix the proven cause, for example the Selenium HTTP read timeout, a driver or Edge crash, or a Capybara wait. Keep the evidence logging only if it stays cheap and CI-only; otherwise remove it in the final commit. Failing unit test first for any new option. Local runs stay unchanged. After three more failed CI attempts, stop and report the evidence to the coordinator.
11. Evidence from the step 10 logs (coordinator, CI run 39394524712, attempt 6 failed after 5 passes since the logging commit; failing test `navigation does not show a separate filters menu`, which only visits the root page). What the log shows: msedgedriver logged `Timed out receiving message from renderer: 300.000` while it waited for a command to finish, and the Selenium client got `Net::ReadTimeout`. So a command (`ClickElement` or `SetWindowRect`) got no answer from the renderer. Facts and limits: (a) `test/test_helper.rb` runs `parallelize(workers: :number_of_processors)`, so the system tests run several Edge instances at once on a small runner; (b) every worker writes the same `tmp/screenshots/msedgedriver.log` and `selenium.log`, so only part of the evidence survived (two sessions in the driver log). Do this: first give every worker its own log files (suffix with `Process.pid`) so the next failure is fully visible. Then test the hypothesis that parallel Edge instances starve each other: run the system tests on CI with one worker (for example `PARALLEL_WORKERS` read in `test_helper.rb`, system tests only, local runs unchanged) and rerun the `system-test` job at least five times (`gh run rerun <run> --job <job>`; the job id changes per attempt). Accept the change only after five passes in a row and state plainly that five passes are evidence, not proof. If the hypothesis fails, report the new logs and stop. No `.github/workflows` edit. Failing unit test first for any new option. Remove the evidence logging in the final commit only if the cause is proven fixed.

12. Implement note for step 11 (implement stage): per-process log files are done (`log_path`). The one-worker change is not done, because its premise does not hold. The appkit `rails-ci.yml` sets no `PARALLEL_WORKERS`. Rails parallelizes only above 50 tests (`test_parallelization_threshold`), and `test:system` loads 17. A local `CI=1 bin/rails test:system` run wrote one `msedgedriver-<pid>.log` and one `selenium-<pid>.log` (a single process) and passed 17 of 17. So CI runs one Edge instance already, and a `PARALLEL_WORKERS=1` setting would change nothing. The renderer timeout needs another hypothesis; the per-process logs give the next failure's evidence. Decision for the coordinator: how to proceed.
13. Evidence from the per-process logs (coordinator, CI run 39616858756; commit c151e9f passed 4 of 6 runs, failed 2). Each failing run has one msedgedriver log, so one Edge instance runs and parallelism is ruled out. The failing test differs per run. In the driver log the click command sends `Runtime.callFunctionOn` (id 129, `awaitPromise: true`, the click-point script for an element at y=864) and Edge never answers it. Edge still answers the driver's `Runtime.evaluate("1")` poll every 500 ms. After 300 s the driver reports `Timed out receiving message from renderer`. No mouse event is sent. Etienne chose option 1: test the render hypothesis on CI only. In `CI_ARGUMENTS` replace `--disable-gpu` with `--disable-renderer-backgrounding` and `--disable-backgrounding-occluded-windows`, and add `--disable-features=CalculateNativeWinOcclusion`. Change one thing: these flags only, no other option. Failing unit test first (the CI argument list). Local runs stay unchanged. Push, then rerun the `system-test` job at least five times (`gh run rerun <run> --job <job>`; fetch the job id fresh each time). Report the pass and fail counts and the logs of any failure. Five passes in a row are evidence, not proof. If a run still hangs, stop and report; do not add more flags. No `.github/workflows` edit.

## Risks

- First run needs network for Selenium Manager to fetch `msedgedriver`. Later runs use its cache. The old code chose a cached Chrome so tests ran offline; this plan accepts a networked first run as the price of a driver that matches the browser.
- Edge auto-updates. Selenium Manager resolves the matching driver per Edge version, so the drift that broke Chrome for Testing does not recur. A brief gap is possible if Edge updates before Microsoft publishes the driver.
- CI depends on the runner image keeping Edge. If a future image drops it, Selenium Manager can still download Edge on Linux. A workflow edit stays out of scope unless CI proves it necessary.
- A known date-dependent flake exists in the budget suggestion system test: it fails on days when an amount ends in 0. A red run from it is not a browser regression. Re-check on its failure message before attributing anything to Edge.
- Rejected: `driven_by :selenium, using: :edge` — Rails yields `nil` options for `:edge`, so there is no way to add `--headless`. Rejected: patching `ActionDispatch::SystemTesting::Browser` — monkeypatching Rails for a test driver is worse than one registered driver. Rejected: keeping a Chrome fallback — the intent says Edge only.

## Out of scope

- Adding or rewriting system tests; parallel system runs; other browsers.
- Any change to `.github/workflows/` (CI already has Edge) or to application code.
- Removing the cached Chrome or ChromeDriver from `~/.cache/selenium` on the developer machine.

## Proof

- Running `bin/rails test:system` on this machine starts headless Edge and all system tests pass → check: `bin/rails db:test:prepare test:system` reports 17 runs, 0 failures, 0 errors, 0 skips; plus `test/application_system_test_case_test.rb` `"system tests are driven by headless Edge"` and `"Edge options run headless"`.
- No system test is skipped, removed or weakened → check: `git diff origin/main --stat -- test/system` is empty and the suite reports 0 skips.
- The test case no longer reads the Chrome for Testing cache → check: `grep -nE "cache/selenium|SE_CACHE_PATH|CHROME" test/application_system_test_case.rb test/application_system_test_case_test.rb` prints nothing; plus `test/application_system_test_case_test.rb` `"the Chrome for Testing lookup is gone"`.
- Setting the Edge binary override makes the tests use that binary → `test/application_system_test_case_test.rb` `"EDGE_BIN sets the Edge binary"`; plus check: `EDGE_BIN=/nonexistent/msedge bin/rails test test/system/search_dialog_test.rb` errors on that path.
- CI runs the system tests on Edge and stays green → check: the pull request's CI `system-test` job passes.

Per changed file, the unit tests expected, named as behaviour:

- `test/application_system_test_case.rb` (tested in `test/application_system_test_case_test.rb`):
  - `"system tests are driven by headless Edge"` — `ApplicationSystemTestCase.driver.name == :headless_edge` and `Capybara.drivers` has `:headless_edge`.
  - `"the Edge driver drives Edge with the Edge options"` — `edge_driver(app, driver_class: fake, options: opts)` calls `fake.new(app, browser: :edge, options: opts)`.
  - `"the Edge driver opens a 1400 by 1400 window"` — the fake browser's window receives `Selenium::WebDriver::Dimension.new(1400, 1400)`.
  - `"Edge options run headless"` — `edge_options(binary: nil).args` includes `"--headless"`.
  - `"an explicit binary is used"` — `edge_options(binary: "/opt/edge").binary == "/opt/edge"`.
  - `"without a binary Selenium Manager picks the installed Edge"` — `edge_options(binary: nil).binary` is `nil`.
  - `"EDGE_BIN sets the Edge binary"` — with `ENV["EDGE_BIN"] = "/opt/edge"`, `edge_options.binary == "/opt/edge"`; an empty `EDGE_BIN` leaves it `nil`. Restore the old value in `ensure`.
  - `"the Chrome for Testing lookup is gone"` — `ApplicationSystemTestCase` does not respond to `chrome_binary`.

Test setup: no fixtures. The unit tests never start a browser. The driver tests use a small fake driver class defined in the test file: its `new` records the arguments and returns an object whose `browser.manage.window.size=` records the dimension. The `EDGE_BIN` test saves and restores the environment variable itself.

Note: `test/system/login_theme_test.rb` inherits `ActionDispatch::IntegrationTest` and starts no browser, so it never serves as a browser check. The single-file checks use `test/system/search_dialog_test.rb`.

---
Domain skills applied: rails-testing, ruby-style, dependencies (no new gem; Selenium Manager is part of `selenium-webdriver`).

## Critique

### Round 1 (codex exec -p terra)

- The single-file and `EDGE_BIN` checks used `test/system/login_theme_test.rb`, which inherits `ActionDispatch::IntegrationTest` and starts no browser, so an invalid `EDGE_BIN` could pass unnoticed → fixed (checks now use `test/system/search_dialog_test.rb`; a note under Proof records why)
- The unit tests checked the driver name and isolated options but not that the registered factory builds a `Capybara::Selenium::Driver` for `:edge` with those options and a 1400 by 1400 window → fixed (added `edge_driver` with an injected `driver_class`, and two fake-driver unit tests for the browser, options and window size)

14. Result of step 13 (implement stage): commit 48c8a05 replaced `--disable-gpu` with the three renderer flags in `CI_ARGUMENTS`. CI run 39662774190, `system-test` job: the first run and four reruns passed, so five distinct jobs in a row (119439839353, 119440703089, 119441627442, 119442648597, 119443725998). Five passes are evidence, not proof. No failure, so no new logs.
