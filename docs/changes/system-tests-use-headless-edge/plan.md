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
