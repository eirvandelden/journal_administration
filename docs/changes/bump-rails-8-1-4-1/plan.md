# Plan: Bump Rails to 8.1.4.1

From `intent.md` (2026-11-06). Status: accepted.

## Design

### Domain terms

Not affected: a lockfile change adds and uses no domain term.

### Diagrams

Not affected: no object, table, message or state changes.

### Signatures

Not affected: no Ruby code changes.

Not checked: the project declined Steep and rbs_rails (no `Steepfile`, no `steep` gem).

### Complexity

Not affected: no new code path; queries per request do not change.

### Invariants

Not affected: no domain invariant changes. The only rule that must hold is the intent's constraint: `Gemfile` does not change, and `Gemfile.lock` changes only for Rails and the gems that `bundle update rails` unlocks.

### Alternatives

1. `bundle update rails`, run as `bundle lock --update rails` (chosen). It moves the Rails gems to 8.1.4.1 and lets Bundler move Rails' own dependencies within their constraints. A dry run on a copy of the lockfile on 2026-11-06 moved exactly these gems: the 11 Rails framework gems, `rails` and `railties` from 8.1.4 to 8.1.4.1; `rack` 3.2.7 → 3.2.8; `rails-html-sanitizer` 1.7.1 → 1.7.2; `loofah` 2.25.2 → 2.25.3; `nokogiri` 1.19.4 → 1.19.7; `io-console` 0.9.4 → 0.9.5. It clears every Rails, `rack`, `rails-html-sanitizer`, `loofah` and `nokogiri` advisory.
2. `bundle update --conservative rails`. Rejected: it keeps every gem locked that 8.1.4.1 does not force to move. The 8.1.4.1 `actionview` gemspec requires `rails-html-sanitizer >= 1.7.2`, so the sanitizer still moves to 1.7.2, but `rack` 3.2.7, `loofah` 2.25.2 and `nokogiri` 1.19.4 stay locked with their advisories open.
3. Pin `gem "rails", "~> 8.1.4.1"` in `Gemfile`. Rejected: the intent puts only `Gemfile.lock` in scope, and the existing `~> 8.0` constraint already allows 8.1.4.1.

No `architect` agents ran: a lockfile-only chore has no object model to design, so the three alternatives above are the whole design space.

## Design decisions

- Conflict with the intent, not resolved here: after `bundle update rails`, `bundle exec bundler-audit check` still reports `addressable` 2.9.0 (7 advisories, fixed in 2.9.1; it comes through `capybara` and `geared_pagination`) and `sqlite3` 2.10.1 (GHSA-4fqr-96q8-xrfx, fixed in 2.10.2; a direct `Gemfile` dependency). Neither is a Rails dependency. The acceptance criterion "bundler-audit reports no vulnerabilities" therefore cannot pass while the intent keeps "Any other gem update" out of scope. A dry run of `bundle lock --conservative --update addressable sqlite3` on top of the Rails bump moves only `addressable` 2.9.0 → 2.9.2 and `sqlite3` 2.10.1 → 2.10.2, and then `bundler-audit check` reports "No vulnerabilities found". Step 4 of the order of work runs only when Etienne approves that extra update (playbook rule 11).
- Conflict with the intent, not resolved here: `bundle exec rubocop` reports 410 offenses on main (391 `Style/RbsInline/MissingTypeAnnotation`, plus other `Style/RbsInline/*` cops) in 120 files. The lefthook pre-push runs rubocop, so this branch cannot push through the hook even after the audit is clean. The intent keeps "Fixing main's rubocop offenses" out of scope, so the outcome "every branch can be pushed again" does not follow from this change alone.
- The `io-console` 0.9.4 → 0.9.5 move is accepted as part of "Rails and its own dependent gems": `railties` depends on `irb`, which depends on `reline` and `io-console`.

## Integration points

- Every Rails framework gem the app loads: Active Record on SQLite, Action Pack routing and controllers, Action View with `rails-html-sanitizer`, Active Storage (chattel warranty documents, receipts), Action Mailbox, Action Text, Active Job on Solid Queue.
- `nokogiri` and `loofah` move a patch level: HTML sanitizing in views and any HTML or XML parsing.
- `rack` moves a patch level: the request layer, including the `/mcp` endpoint.
- The lefthook pre-push hook and `bundler-audit`.

## Files that change

- `Gemfile.lock` — Rails and its dependents move to the versions listed under Alternatives, option 1. Nothing else changes.
- `Gemfile.lock` — only after Etienne approves the decision above: `addressable` 2.9.0 → 2.9.2 and `sqlite3` 2.10.1 → 2.10.2.

`Gemfile` does not change. No application code, test, migration, deploy file or linter config changes.

## Order of work

No acceptance criterion needs a new test: this is a dependency change with no behaviour change. The checks run after the change.

0. Baseline, before the lockfile changes: clear `tmp/cache/bootsnap`, run `bin/rails test` and `bin/rails test:system` on the unchanged branch, and record the result in the report. A failure here belongs to main, not to the bump: record it and keep it apart from the step 5 results. The budget suggestion system test is known to fail on dates where an amount ends in 0; note it when it fails, in both runs.
1. In the worktree, run `bundle lock --update rails`, then `bi`. `bundle lock --update rails` resolves the lockfile exactly as `bundle update rails` does, without installing; `bi` installs (the playbook forbids `bundle install`). This is the command the 2026-11-06 dry run used. Never update without a gem name.
2. Run `git diff --stat` and `git diff Gemfile.lock`. Confirm that only `Gemfile.lock` changed, and that the changed gems are exactly the list under Alternatives, option 1, plus their platform variants and checksums. Stop and report if any other gem moved.
3. Run `bundle exec bundler-audit check`. Expect only the `addressable` and `sqlite3` advisories to remain.
4. Only when Etienne approved the extra update: run `bundle lock --conservative --update addressable sqlite3`, then `bi`. Repeat step 2 for these two gems and run `bundle exec bundler-audit check` again. Expect "No vulnerabilities found". Without approval, skip this step and report the remaining advisories.
5. Clear `tmp/cache/bootsnap`. Run `bin/rails test`. Then run `bin/rails test:system`. Compare with the step 0 baseline: any new failure belongs to the bump.
6. Run `bundle exec brakeman --no-pager -q`. Expect no warnings.
7. Run `bin/rails runner 'puts Rails.version'`. Expect `8.1.4.1`.
8. Smoke-check that the app boots on the new gems: start `DISABLE_SSL=1 bin/rails server -p 3001 -b 127.0.0.1` in the background, find the sign-in path with `bin/rails routes -g session` (the `Appkit` engine owns it), request it with `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3001<path>` and expect `200`, then stop the server. The system tests already cover authenticated pages.
9. Commit `Gemfile.lock` alone: `Bump Rails to 8.1.4.1`. When step 4 ran, commit it apart: `Bump addressable and sqlite3 for security advisories`.
10. Before any push, run `npm install` in the worktree (the herb pre-push hook needs `node_modules`) and put the worktree's `bin/` first on `PATH` (the binstub gotcha in `AGENTS.md`). The push still fails on rubocop until the rubocop decision above is settled.

## Risks

- A test breaks on 8.1.4.1 or on the `nokogiri`/`loofah`/`rails-html-sanitizer` patch. Security releases can tighten sanitizing or parameter parsing. Response: fix the code that the test exercises, within the intent's "unless 8.1.4.1 breaks a test" clause; never weaken the test.
- `nokogiri` 1.19.7 ships native platform gems. The lockfile must keep every platform it lists today (darwin, linux gnu and musl for arm and x86). Step 2 checks the platform variants.
- The audit database moves on. New advisories can appear between this plan and the implement stage. Step 3 reports what it sees; any new non-Rails advisory joins the `Decision needed` about extra gems.
- The push stays blocked by rubocop (see Design decisions). Bypassing the hook is not part of this plan.
- GHSA-2gff-2mmg-m73p changes `ActionDispatch::RemoteIp`: with `ip_spoofing_check` on (the default here), a request that carries both a `Forwarded` and an `X-Forwarded-For` header with different client addresses now raises `ActionDispatch::RemoteIp::IpSpoofAttackError`. Production runs behind kamal-proxy with `forward_headers: true` (`config/deploy.yml`). A local boot cannot exercise this path. If the proxy, or anything in front of it, sets `Forwarded` with a client address that differs from `X-Forwarded-For`, every proxied request fails after deploy. Deployment is out of scope for agents, so the report hands Etienne this post-deploy check: one request through the proxy without a `Forwarded` header must succeed, and the production log must hold no `IpSpoofAttackError`. Any configuration change in response is a new decision, not part of this plan.
- Rejected: `bundle update` for all gems (forbidden by playbook rule 11 and the intent), a `Gemfile` pin (out of scope), `--conservative rails` (leaves advisories open).

## Proof

- `bundle exec bundler-audit check` reports no vulnerabilities → check: `bundle exec bundler-audit check` prints "No vulnerabilities found". Holds only after step 4; without it, the check lists the `addressable` and `sqlite3` advisories and nothing else.
- The full test suite stays green → check: `bin/rails test` and `bin/rails test:system` exit 0.
- Brakeman stays green → check: `bundle exec brakeman --no-pager -q` reports no warnings.
- Rails runs 8.1.4.1 → check: `bin/rails runner 'puts Rails.version'` prints `8.1.4.1`.
- No new test failure against the baseline → check: the step 5 results hold no failure that the step 0 baseline did not hold.
- The app boots on 8.1.4.1 → check: step 8's request to the sign-in path returns `200`.
- Only Rails and its dependents move → check: `git diff --stat main` lists only `Gemfile.lock` and the change folder, and `git diff main -- Gemfile.lock` holds only the gems listed under Alternatives, option 1 (plus `addressable` and `sqlite3` after step 4).

Per changed file, the unit tests expected:
- `Gemfile.lock`: none. Configuration has no tests.

Test setup: the existing fixtures and suite; nothing new.

---
Domain skills applied: dependencies, rails-upgrade (patch release, no `load_defaults` change).

## Critique

### Round 1 (codex exec -p terra)

- The plan cannot meet the accepted outcome within its scope: a clean audit needs non-Rails updates of `addressable` and `sqlite3`, and the pre-push rubocop failure keeps branches unpushable; amend and re-accept the intent, or narrow the outcome. → dismissed: only Etienne can widen the intent or narrow its outcome, and auto mode forbids a guess. The plan already names both conflicts under Design decisions and gates step 4 on his approval; the report raises both as decisions.
- No green baseline before the lockfile changes, so a later failure cannot be assigned to the patch release. → fixed (step 0 records a baseline run of the unit and system suites; step 5 compares against it; a Proof line names the comparison)
- The most relevant behaviour change is missed: 8.1.4.1 raises `IpSpoofAttackError` on conflicting `Forwarded` and `X-Forwarded-For` headers, and production runs behind kamal-proxy with `forward_headers: true`. → fixed (Risks names the change, verified against the advisory text in the local ruby-advisory-db, and hands Etienne a post-deploy check; no configuration change, since deployment and deploy files are out of scope)
- Design alternative 2 contradicts itself: conservative resolution must still move `rails-html-sanitizer` to 1.7.2. → fixed (alternative 2 now says the sanitizer moves while `rack`, `loofah` and `nokogiri` stay locked with open advisories)
- The manual boot check refers to an external memory and an unspecified authenticated user and page. → fixed (step 8 is now a self-contained unauthenticated curl smoke check of the sign-in path; the system suite covers authenticated pages)
