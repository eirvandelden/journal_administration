# Plan: Fix the sqlite3 security advisory

From `intent.md` (2026-11-06). Status: accepted.

## Design

### Domain terms

Not affected: the change touches no domain object; no glossary term is added or reused. In this plan, a **platform entry** is one `sqlite3 (<version>[-<platform>])` line in `Gemfile.lock`.

### Diagrams

Not affected: no Ruby object, table or flow changes.

### Signatures

Not affected: no Ruby method is added or changed. `SQLite3Configuration#configure_connection` in `config/initializers/sqlite3.rb` stays as it is.

Not checked: the project has no Steepfile and no `sig/` directory.

### Complexity

Not affected: no request path changes; query counts stay the same.

### Invariants

- `Gemfile.lock` locks `sqlite3` at 2.10.2 for the `ruby` platform and for the nine native platforms it already lists, enforced by Bundler at boot (`Bundler.setup` refuses a lockfile that does not resolve).
- Each of the ten `sqlite3` lines under `CHECKSUMS` holds the SHA-256 that Bundler fetched from `https://gem.coop`, never a hand-copied hash, enforced by Bundler on install.
- The `Gemfile.lock` diff is exactly 20 removed and 20 added lines, every one a `sqlite3` platform entry. `mini_portile2 (2.8.9)`, `RUBY VERSION ruby 4.0.7p0` and `BUNDLED WITH 4.0.22` do not change. Enforced by the diff checks in `## Proof`.

### How 2.10.2 reaches this app

The 2.10.2 release does more than fix the truncation. It also raises `RangeError` for strings over `INT_MAX` bytes, changes what happens when a SQLite callback raises, and keeps per-fiber state in `Thread.current`. The app does not reach the changed behaviour in normal operation:

- Custom `busy_handler` (`config/initializers/sqlite3.rb:8`): installed only when `@config[:retries]` is set. `config/database.yml` sets no `retries` key, so the block never runs. The block also never raises.
- Rails' own busy handler: `timeout: 5000` (`config/database.yml:43`) and `timeout: 20000` (`config/database.yml:78`) make Rails set `busy_handler_timeout`, whose block does not raise. The 2.10.2 change only fixes a deadlock when a callback raises or a thread interrupt arrives during lock contention.
- No `create_function`, collation, `trace` or authorizer exists in `app/`, `config/` or `lib/`.
- Nothing freezes a `Thread`. No SQL string or bound value comes near 2 GiB; files go to Active Storage on disk.

The existing suite runs the `busy_handler_timeout` path on every test connection, so it is the proof that the app behaves as before.

### Alternatives

1. `bundle update sqlite3` plus a diff guard — chosen. It is the command `intent.md` names. Today it resolves to exactly 2.10.2: 2.10.2 is the newest `sqlite3` and `mini_portile2` 2.8.9 is the newest `mini_portile2`, and 2.10.2 has the same runtime dependency (`mini_portile2 ~> 2.8.0`) as 2.10.1. The diff guard in step 4 catches any other line that moves.
2. `bundle update sqlite3 --patch --strict --conservative` (architect, minimal-diff goal) — rejected. The flags would keep the resolver inside 2.10.x and stop `mini_portile2` from moving. They add no protection today, the diff guard catches the same drift, and they change the command `intent.md` names.
3. Raise the `Gemfile` constraint to `>= 2.10.2` — rejected. `intent.md` forbids a `Gemfile` constraint change.
4. Edit `Gemfile.lock` by hand — rejected. The ten checksums must come from the gem source, and a hand edit risks a lockfile Bundler later rewrites.
5. A new contention or interruption test around the busy handler (architect, behaviour-safety goal, and the critique) — rejected. The custom handler is dead code under the current `database.yml`, and a contention test would be slow and flaky and would test the gem's fix, not app behaviour.

## Design decisions

- Use the literal `bundle update sqlite3` from `intent.md`, guarded by the diff checks, rather than add flags. No conflict with `## Decisions`.
- No new test. The change is a dependency patch bump, which counts as configuration; the existing suite proves "the app behaves as before". `intent.md` allows a code change only if 2.10.2 breaks a test.
- The repository has no `x64-mingw-ucrt` platform in `PLATFORMS`. The plan does not add it, so the diff stays at the ten existing platform entries.
- Conflict with `intent.md` `## Decisions`: the decision "CI never runs Bundler Audit" is false. `.github/workflows/ci.yml:8` calls `eirvandelden/appkit/.github/workflows/rails-ci.yml@main`, whose job runs `bin/bundler-audit`. The push in step 9 still succeeds, so the acceptance criterion "the branch reaches `origin`" holds. But the pull request's CI audit job stays red until the other advisories are fixed (`bump-rails-security-advisories`, `bump-rails-8-1-4-1`), and autonomous delivery waits for green CI. This plan does not change CI or `config/bundler-audit.yml`, because both are out of scope. The coordinator must ask Etienne how to proceed.

## Integration points

- The gem source `https://gem.coop` (the `source` in `Gemfile` and the `remote` in `Gemfile.lock`): `bundle update` resolves `sqlite3` 2.10.2 there and fetches checksums for every locked platform.
- Bundler Audit: its advisory database must no longer list `sqlite3`. Refresh it with `bundle exec bundler-audit update` before the check.
- Lefthook pre-push (`lefthook.yml`): runs rubocop, herb, Brakeman, `bundler_audit` and the tests. The push skips `bundler_audit` and `rubocop` with `LEFTHOOK_EXCLUDE=bundler_audit,rubocop`; see `## Coordinator decisions`.
- CI (`.github/workflows/ci.yml`, shared appkit workflow): runs `bin/bundler-audit` on the pull request; see `## Design decisions`.
- Production (Kamal, Linux) installs the native gem for its platform from the lockfile. No deploy file changes.
- Dependabot pull request #401 (`dependabot/bundler/sqlite3-2.10.2`) makes the same bump. Open Dependabot pull requests are out of scope; it becomes redundant once this change merges.

## Files that change

- `Gemfile.lock` — the ten `sqlite3 (2.10.1…)` spec lines under `GEM` and the ten `sqlite3 (2.10.1…)` lines under `CHECKSUMS` move to 2.10.2 with the new SHA-256. Nothing else.

No other file changes. Not `Gemfile`, not `db/schema.rb`, not any file under `app/`, `config/`, `test/` or `.github/`.

## Order of work

1. Confirm the starting point: `bundle exec bundler-audit update`, then `bundle exec bundler-audit check` lists GHSA-4fqr-96q8-xrfx for `sqlite3` 2.10.1.
2. Put this worktree's `bin/` first on `PATH` for every command (`export PATH="$PWD/bin:$PATH"`), because the Rails binstubs otherwise resolve to the main checkout. Run `npm install` in the worktree if `node_modules` is missing, so herb works.
3. Run `bundle update sqlite3`. If Bundler only resolves and does not install the gem, run `bi` (never `bundle install`).
4. Run the lockfile checks from `## Proof`. If any other line moves (`mini_portile2`, `BUNDLED WITH`, any other gem), run `git checkout Gemfile.lock` and stop: report it as a blocker.
5. Run the version check from `## Proof` and confirm `2.10.2`.
6. Run the audit check from `## Proof`. The other gems may still fail Bundler Audit; that is expected.
7. Run the checks by hand: `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bin/rails test`, `bin/rails test:system`.
8. Commit `Gemfile.lock` alone: `Bump sqlite3 to 2.10.2 for GHSA-4fqr-96q8-xrfx`.
9. Push with `LEFTHOOK_EXCLUDE=bundler_audit,rubocop git push -u origin HEAD`, with the worktree `bin/` first on `PATH`. Run the push check from `## Proof`.

## Risks

- A test fails on 2.10.2. `### How 2.10.2 reaches this app` shows no path the app reaches changes in normal operation, so this is unlikely. If it happens, follow `intent.md`: fix the code that breaks, with a regression test first. Do not pin back to 2.10.1.
- `bundle update sqlite3` moves `mini_portile2`, `BUNDLED WITH` or another line. Step 4 catches it and stops the work.
- The pre-push hook runs the main checkout's app. Step 2 puts the worktree `bin/` first on `PATH`.
- The pull request's CI stays red on the audit job until the other advisories are fixed. See `## Design decisions`; this needs Etienne's decision, not a workaround in this change.
- The system test for budget suggestions is date-flaky on days an amount ends in 0. A failure there that also fails on `main` is not caused by this change; record it in the report rather than skipping it.
- Rejected: flags on `bundle update`, a `Gemfile` pin, a hand-edited lockfile, a full `bundle update`, a contention test (see `### Alternatives`).

## Proof

- Bundler Audit reports no `sqlite3` advisory → check: `bundle exec bundler-audit update && ! bundle exec bundler-audit check 2>&1 | grep -q "Name: sqlite3"` exits 0.
- The `Gemfile.lock` diff holds only `sqlite3` lines → check: all of `git diff --quiet main -- Gemfile`, `test "$(git diff --numstat main -- Gemfile.lock)" = "$(printf '20\t20\tGemfile.lock')"` and `! git diff -U0 main -- Gemfile.lock | grep '^[-+] ' | grep -qv 'sqlite3 (2\.10\.'` exit 0, and `git diff --name-only main` lists only `Gemfile.lock` and files under `docs/changes/fix-sqlite3-advisory/`.
- The full test suite, system tests, herb and Brakeman stay green → check: `bin/rails test`, `bin/rails test:system`, `npx @herb-tools/linter app/views/` and `bundle exec brakeman --no-pager -q` each exit 0.
- Rubocop reports no offense that `main` does not already have → check: the offense count of `bundle exec rubocop --format offenses` on the branch equals the count on `main` (only `Gemfile.lock` changes, and rubocop does not inspect it).
- The branch reaches `origin` while the other gems still fail Bundler Audit → check: `LEFTHOOK_EXCLUDE=bundler_audit,rubocop git push -u origin HEAD` exits 0, then `test "$(git rev-parse HEAD)" = "$(git ls-remote origin refs/heads/fix-sqlite3-advisory | cut -f1)"` exits 0.
- Invariant: the app loads `sqlite3` 2.10.2, enforced by `Gemfile.lock` and Bundler → check: `bundle exec ruby -e 'require "sqlite3"; puts SQLite3::VERSION'` prints `2.10.2`.
- Invariant: `mini_portile2`, `RUBY VERSION` and `BUNDLED WITH` stay unchanged, enforced by the diff checks above → check: `grep -q "mini_portile2 (2.8.9)" Gemfile.lock && grep -q "4.0.22" Gemfile.lock` exits 0.

Per changed file, the unit tests expected:
- `Gemfile.lock`: none; configuration has no tests. The existing suite proves the behaviour stays the same.

Test setup: existing fixtures under `test/fixtures`; nothing new.

## Coordinator decisions (2026-11-06)

- Etienne chose to push now and accept the pre-existing red `ci / lint` (RbsInline offenses, `fix-rbs-inline-offenses`) and `ci / scan_ruby` (other advisories, `bump-rails-security-advisories`) jobs. The push also skips the rubocop pre-push hook. The rubocop criterion is "no new offense".
- Dependabot PR #401 stays out of scope; this change goes ahead.

## Out of scope

- Other gems with advisories (Rails 8.1.4 gems, rack, nokogiri, loofah, rails-html-sanitizer, addressable): `bump-rails-security-advisories` and `bump-rails-8-1-4-1` cover them.
- Open Dependabot pull requests, including #401.
- `Gemfile`, deploy files, migrations, CI workflows, `config/bundler-audit.yml` and system tools.
- Adding the `x64-mingw-ucrt` platform.

---
Domain skills applied: dependencies, software-design (design alternatives).

## Critique

### Round 1 (codex exec -p terra)

- The intent decision "CI never runs Bundler Audit" is false: `.github/workflows/ci.yml` calls the appkit reusable workflow, which runs `bin/bundler-audit`, so pull request CI stays red on the other advisories → fixed (recorded as a conflict with `## Decisions` in `## Design decisions`, `## Integration points` and `## Risks`; raised as a decision for Etienne; the push criterion still holds)
- The plan added `--conservative` although `intent.md` names `bundle update sqlite3` → fixed (plan uses the literal command plus a diff guard; flags moved to `### Alternatives` as rejected)
- The plan names RubyGems as the source, but `Gemfile` and `Gemfile.lock` use `https://gem.coop` → fixed (Invariants and Integration points name gem.coop)
- The claim that 2.10.2 only fixes truncation is false; it also changes callback exception behaviour and the app registers a `busy_handler` → fixed (claim removed; new `### How 2.10.2 reaches this app` shows the custom handler never installs and no reached path changes; a contention test is a rejected alternative)
- The plan names Dokku for production, but the repository deploys with Kamal → fixed (Integration points say Kamal)
- The audit Proof uses `grep -c`, which exits 1 on success, and may read a stale advisory database → fixed (Proof runs `bundler-audit update` and uses `! … grep -q`)
- The lockfile Proof has the same `grep -c` exit-status defect → fixed (Proof uses `git diff --numstat` equality and `! … grep -qv`)
- The push Proof shows the remote SHA but never compares it with `HEAD` → fixed (Proof compares `git rev-parse HEAD` with `git ls-remote`)
- The plan skipped the architect agents that autonomous planning still requires → fixed (two architects ran, minimal-diff and behaviour-safety goals; their designs feed `### Invariants`, `### How 2.10.2 reaches this app` and `### Alternatives`)
