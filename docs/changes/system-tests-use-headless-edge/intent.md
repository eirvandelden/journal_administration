# Intent: Run system tests on headless Edge

Author: Etienne van Delden. Status: accepted. Type: chore. Delivery: autonomous

## Problem

The system tests drive a Selenium-managed Chrome for Testing build from a local cache. That build and its ChromeDriver drift apart: ChromeDriver supports Chrome 155, the cached Chrome is 150, and 16 of 17 system tests cannot start. Edge is always installed and up to date on the developer machine.

## Proposed outcome

The system tests run in headless Edge. They start on the developer machine without any manual browser or driver setup, and they pass.

## Affected users and systems

- The developer who runs `bin/rails test:system`.
- `test/application_system_test_case.rb` and the system tests under `test/system`.
- CI, which runs the system tests today (`run_system_tests: true` in `.github/workflows/ci.yml`).

## Constraints

- Edge only: Chrome is no longer the driver, locally or in CI.
- No new gem and no system tool installs or upgrades (rules 8 and 11). Selenium Manager, already part of `selenium-webdriver`, may fetch the matching `msedgedriver` into its own cache.
- Approved permission: a minimal edit of `.github/workflows` only when the plan shows CI cannot run Edge without it. Anything else there is a stop-and-ask.
- Base on `origin/main`.

## In scope

- Switch the system test driver to headless Edge, with the screen size kept at 1400 by 1400.
- Remove the Chrome for Testing cache lookup that the switch makes obsolete.
- An environment override for the Edge binary, where the current `CHROME_BIN` override exists.
- Run all system tests on Edge and fix breakage that comes from the browser change.
- Update the repository notes (`AGENTS.md` or README) where they name Chrome for system tests.

## Out of scope

- Adding or rewriting system tests.
- Other browsers, parallel system test runs, or CI redesign.
- Any change to application code.

## Acceptance criteria

- Running `bin/rails test:system` on this machine starts headless Edge and all system tests pass.
- No system test is skipped, removed or weakened to get there.
- The test case no longer reads the Chrome for Testing cache.
- Setting the Edge binary override makes the tests use that binary.
- CI runs the system tests on Edge and stays green.

## Open questions

None.
