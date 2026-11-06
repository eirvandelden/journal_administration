# Plan: Bump gems with open security advisories

From `intent.md` (2026-11-06). Status: accepted.

## Design

### Domain terms

- No glossary term changes. Nothing is added to `GLOSSARY.md`.
- Working terms for this plan only:
  - **Advisory gem**: a gem that `intent.md` names: the Rails 8.1.4 components (`rails`, `railties`, `actioncable`, `actionmailbox`, `actionmailer`, `actionpack`, `actiontext`, `actionview`, `activejob`, `activemodel`, `activerecord`, `activestorage`, `activesupport`), `rack`, `nokogiri`, `loofah`, `rails-html-sanitizer`, `addressable` and `sqlite3`.
  - **Conservative patch update**: `bundle update <advisory gems> --conservative --patch --strict`. It moves only the named gems to their newest patch release and leaves every other gem, shared dependencies included, on its current version.

### Diagrams

Not affected: the change adds no object, message, table or state.

### Signatures

Not affected: no Ruby code changes. The only artefact is `Gemfile.lock`.

Not checked: this project declined Steep and rbs_rails; no Ruby method changes here anyway.

### Complexity

Not affected: there is no new runtime path and no query change.

### Invariants

- `Gemfile` does not change. Check: `git diff --quiet main -- Gemfile`.
- In `Gemfile.lock`, only advisory gems change version or dependency list. `PLATFORMS`, the `GIT`/`GEM` sources and `DEPENDENCIES` stay identical. Check: the lockfile check in `## Proof`.
- Every advisory gem reaches its minimum patched version and stays inside its current minor version. `--patch --strict` enforces it; the lockfile check proves it.
- Bundler Audit reports no vulnerabilities. The lefthook pre-push hook enforces this.

### Alternatives

- **A. One conservative patch update, one commit (chosen).** Verified on a scratch copy of the lockfile on 2026-11-06: the command resolves to rails 8.1.4.1 (all components), rack 3.2.8, nokogiri 1.19.7, loofah 2.25.3, rails-html-sanitizer 1.7.2, addressable 2.9.2 and sqlite3 2.10.2. No other gem version changes, every platform stays, and `bundler-audit check` then reports no vulnerabilities.
- **B. One commit per gem family (rejected).** The families are coupled: actionview 8.1.4.1 needs rails-html-sanitizer >= 1.7.2, which needs loofah >= 2.25.3, which needs nokogiri >= 1.19.5. The commits must therefore land in a fixed bottom-up order. Every commit except the last still fails Bundler Audit, so no intermediate commit is green under the pre-push hook. It costs five full suite runs for a security fix that is one logical change.
- **C. `bundle update rails` without `--conservative` (rejected).** It also bumps transitive dependencies such as i18n, zeitwerk and concurrent-ruby. That breaks the intent's constraint that the lockfile diff holds only the advisory gems and their direct dependencies.

## Design decisions

- The update list names every Rails component and `railties` by hand, not just `rails`. With `--conservative --strict`, a component left off the list stays on 8.1.4 and the resolve fails or splits.
- The command is `bundle update` (the intent's constraint), with the same flags as the verified `bundle lock --update` run. Both use the same resolver; `bundle update` also installs the gems. If installation fails, run `bi` (never `bundle install`).
- No new tests. A dependency bump is configuration; the existing suite is the regression net. Three gaps get a manual browser check instead, per playbook rule 22: no test fetches an Active Storage blob, no test uploads a file through a multipart form, and no test renders hostile markup through `simple_format`.
- The lockfile proof is a Ruby script that parses both lockfiles with `Bundler::LockfileParser` and fails on any unexpected change. A `git diff | grep` reads only changed spec lines and cannot assert versions.
- No conflict with `intent.md`'s `## Decisions`: the bump happens now, on its own branch, and nothing else rides along.

## Integration points

- Bundler and the `gem.coop` source: the update fetches the new gem versions.
- Lefthook pre-push: rubocop, herb, brakeman, Bundler Audit and `bundle exec rails test` run on every push. System tests do not run there.
- GitHub Actions CI (`.github/workflows/ci.yml`): calls the reusable `eirvandelden/appkit` Rails workflow with `run_system_tests: true`, plus a herb job. Its runner and install details live in that reusable workflow; the pull request's CI result is the proof that tests and system tests pass on Linux.
- Production deploy installs from the same `Gemfile.lock`. Deploy files are out of scope and do not change.
- Code paths the advisory fixes can touch:
  - Active Storage serving and analysis: `Chattel#warranty_document`, `Receipt#invoice`, `Transaction#proof_of_purchase`, linked through `rails_blob_path(..., disposition: :inline)` in `app/views/transactions/show.html.erb`, `app/views/receipts/_basket.html.erb` and `app/views/chattels/show.html.erb`.
  - Multipart uploads through rack: the `proof_of_purchase` file field.
  - Sanitizing: `simple_format(@chattel.notes)` in `app/views/chattels/show.html.erb`. `test/integration/chattels_show_test.rb` checks line breaks only, not sanitised markup; step 8 checks that by hand.
  - Cookies and session: the `session_token` cookie from the `appkit` gem, covered by `test/integration/session_cookie_test.rb` and `test/channels/application_cable/connection_test.rb`.
  - Host handling: `allowed_hosts` in `app/controllers/assistant_controller.rb`, covered by the assistant integration tests. The app has no `trusted_proxies` or `remote_ip` use, so the RemoteIp fix changes nothing here.

## Files that change

- `Gemfile.lock` — the advisory gems move to their patched versions. Nothing else.

## Order of work

No acceptance criterion needs a new test, so the work starts with the change and the checks run after it.

1. In the worktree, confirm the starting state: `bundle exec bundler-audit check --update` lists the advisory gems and fails.
2. Run the conservative patch update:
   ```
   bundle update rails railties actioncable actionmailbox actionmailer actionpack actiontext actionview activejob activemodel activerecord activestorage activesupport rack nokogiri loofah rails-html-sanitizer addressable sqlite3 --conservative --patch --strict
   ```
   Do not pipe its output into a file; the `useragent` GitHub gem prints "Fetching" lines to stdout.
3. Run the lockfile check and the `Gemfile` check from `## Proof`. Stop and report if either fails.
4. Run `bundle exec bundler-audit check`. It must report no vulnerabilities.
5. Clear `tmp/cache/bootsnap`. If `node_modules` is missing, run `npm ci` (never `npm install`, which can rewrite `package-lock.json`). Then `git status --short` must show only `Gemfile.lock` outside the change folder.
6. Run `PATH="$PWD/bin:$PATH" bin/rails test`, then `PATH="$PWD/bin:$PATH" bin/rails test:system`.
7. Run `bundle exec rubocop`, `npx @herb-tools/linter app/views/` and `bundle exec brakeman --no-pager -q`.
8. Manual check (rule 22). Copy the main checkout's development databases into the worktree with the `using-sqlite-worktrees` skill's helper; it checkpoints WAL. The databases live under `storage/db/` (`development.sqlite3`, `development_cache.sqlite3`, `development_queue.sqlite3` and the cable database in `config/database.yml`); if the helper misses that folder, copy each with `sqlite3 <main checkout>/storage/db/<file> ".backup storage/db/<file>"`. Then run `PATH="$PWD/bin:$PATH" bin/rails db:migrate` and `DISABLE_SSL=1 PATH="$PWD/bin:$PATH" bin/dev -p 3001`, and browse `http://127.0.0.1:3001`. Sign in, then:
   - attach a PDF as proof of purchase on a transaction, save, and open the attachment link: the PDF shows;
   - set a chattel's notes to `<script>alert(1)</script><a href="javascript:alert(1)">x</a> line` and open the chattel: no alert runs, and the link has no `javascript:` href;
   - record both results, revert the chattel notes, and never commit the re-dumped `db/schema.rb`.
9. Commit `Gemfile.lock` alone: `chore(deps): bump gems with security advisories`. Stage it by name.
10. Push with the worktree's `bin/` first on `PATH`: `PATH="$PWD/bin:$PATH" git push`. The pre-push hook runs rubocop, herb, brakeman, Bundler Audit and the test suite again; system tests run in CI only.
11. Hand over to the coordinator's chain: review, then `deliver`, then `gh pr checks --watch`.

## Risks

- A patch release changes behaviour the suite does not cover. Active Storage serving, multipart upload and sanitised notes have no test; step 8 covers them by hand.
- Session cookies from the Rails session store gain a `SameSite` attribute. The app's own `session_token` cookie comes from `appkit` and its tests stay the guard.
- `test/system/budgets_test.rb` "suggesting amounts" is a known date flake: it fails on days a suggested amount ends in 0. Red on only that test is not a regression from this change. Never skip or weaken it.
- Newer patch releases may appear between this plan and the implementation. The command then picks them up. That is fine while they stay inside the same minor version; `--patch --strict` ensures it. The Proof versions are minimums, not exact pins.
- A patch release adds a deprecation warning to the test output. The dependencies skill says to fix it in the same work. A fix that needs production code goes beyond this plan's one file, so the implementer reports it to the coordinator instead of improvising.
- Rejected: a full `bundle update`, a Rails minor upgrade and any `Gemfile` constraint change, all out of scope in `intent.md`.

Out of scope: any other gem, Ruby, a Rails minor or major upgrade, `config.load_defaults`, deploy files, new tests.

## Proof

- Bundler Audit reports no vulnerabilities → check: `bundle exec bundler-audit check --update` prints "No vulnerabilities found".
- The full test suite, system tests, rubocop, herb and brakeman pass → check: `PATH="$PWD/bin:$PATH" bin/rails test`, `PATH="$PWD/bin:$PATH" bin/rails test:system`, `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, all exit 0; then green CI on the pull request.
- The `Gemfile.lock` diff holds only the advisory gems and their direct dependencies → check: the lockfile check below exits 0 and prints "Lockfile OK"; and `git diff --quiet main -- Gemfile` exits 0.
- Invariant: every advisory gem is at least its patched version (each Rails component 8.1.4.1, rack 3.2.8, nokogiri 1.19.5, loofah 2.25.3, rails-html-sanitizer 1.7.2, addressable 2.9.1, sqlite3 2.10.2) and inside its current minor, enforced by `--patch --strict` → check: the lockfile check below.
- Invariant: `PLATFORMS`, sources and `DEPENDENCIES` are unchanged, and no other gem changes version or dependency list, enforced by `--conservative` → check: the lockfile check below.
- The app behaves as before → check: step 8's two manual checks, plus the green suite and CI.

The lockfile check. Save it to a scratch path outside the repository and run it from the worktree root with `bundle exec ruby <path>`. Verified on 2026-11-06: it fails on `main`'s lockfile with one "below" line per advisory gem, and passes on the lockfile the step 2 command produces.

```ruby
require "bundler"

RAILS = %w[rails railties actioncable actionmailbox actionmailer actionpack actiontext actionview
           activejob activemodel activerecord activestorage activesupport].freeze
MINIMUM = RAILS.to_h { [it, "8.1.4.1"] }.merge(
  "rack" => "3.2.8", "nokogiri" => "1.19.5", "loofah" => "2.25.3", "rails-html-sanitizer" => "1.7.2",
  "addressable" => "2.9.1", "sqlite3" => "2.10.2"
).freeze

before = Bundler::LockfileParser.new(`git show main:Gemfile.lock`)
after = Bundler::LockfileParser.new(File.read(ENV.fetch("LOCKFILE", "Gemfile.lock")))
errors = []
errors << "PLATFORMS changed" unless before.platforms.sort_by(&:to_s) == after.platforms.sort_by(&:to_s)
errors << "GIT/GEM sources changed" unless before.sources.map(&:to_lock) == after.sources.map(&:to_lock)
errors << "DEPENDENCIES changed" unless before.dependencies == after.dependencies

index = ->(lock) { lock.specs.to_h { [[it.name, it.platform.to_s], it] } }
old_specs = index.(before)
new_specs = index.(after)
same = ->(a, b) { a && b && a.version == b.version && a.dependencies.sort_by(&:name) == b.dependencies.sort_by(&:name) }
changed = (old_specs.keys | new_specs.keys).reject { same.(old_specs[it], new_specs[it]) }.map(&:first).uniq
extra = changed - MINIMUM.keys
errors << "unexpected gems changed: #{extra.join(', ')}" if extra.any?

MINIMUM.each do |name, minimum|
  old_version = old_specs.values.find { it.name == name }.version
  versions = new_specs.values.select { it.name == name }.map(&:version).uniq
  versions.each do |version|
    errors << "#{name} #{version} is below #{minimum}" if version < Gem::Version.new(minimum)
    errors << "#{name} #{version} left minor #{old_version.segments.first(2).join('.')}" unless version.segments.first(2) == old_version.segments.first(2)
  end
end

abort errors.join("\n") if errors.any?
puts "Lockfile OK. Changed: #{changed.sort.join(' ')}"
```

Per changed file, the unit tests expected:
- `Gemfile.lock`: none; configuration has no tests.

Test setup: none new. The existing fixtures and suite run unchanged.

---
Domain skills applied: dependencies (named-gem update only, no new pins, no major skip, `bi` for installs, fix new deprecation warnings).

## Critique

### Round 1 (codex exec -p terra)

- The version proof only greps lines that already exist; it does not compare versions or cover every Rails component → fixed (Proof now runs a Ruby lockfile check that compares every advisory gem against its minimum and its current minor, verified to fail on `main` and pass on the resolved lockfile)
- The gem-name allowlist reads only changed spec lines and misses the GIT, dependency and PLATFORMS sections → fixed (the same lockfile check compares PLATFORMS, sources, DEPENDENCIES and every spec's version and dependency list)
- `npm install` in step 5 can rewrite `package-lock.json`, which breaks the one-file plan → fixed (step 5 uses `npm ci` and checks `git status` shows only `Gemfile.lock`)
- The plan claims the pre-push hook runs every check, but it runs no system tests, and CI details live in a reusable workflow → fixed (Integration points and step 10 name the hook's five checks; CI is described as the appkit reusable workflow and its result is the Linux proof)
- The manual database copy step names no source or destination and ignores the four WAL databases → fixed (step 8 uses the `using-sqlite-worktrees` helper, names the `storage/db/` files and gives an explicit `.backup` fallback per file)
- The sanitizer coverage claim is wrong: `chattels_show_test.rb` checks line breaks only → fixed (claim corrected; step 8 adds a manual hostile-markup check on chattel notes)
- The Signatures section cites `docs/changes/add-inline-signatures`, which no longer exists → fixed (the Steep decision is stated directly)
