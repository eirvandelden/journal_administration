# Plan: Update dependencies to their latest versions

From `intent.md` (2026-10-06). Status: accepted.

## Context

The app runs on older gems, an older ERB linter, Ruby 4.0.6 and Bundler 2.7.2. This change brings each one to the newest release that the constraints allow, in one branch (`update-dependencies`). It is a personal project: Minitest, fixtures, lefthook, `rv` for Ruby. The worktree is `.worktrees/update-dependencies`; all work happens there.

State on 2026-10-06, read during planning:

- `bundle outdated` lists 27 gems. Direct: `appkit` (git 2dbb638 → fd86991), `brakeman` 8.0.6 → 8.1.0, `herb` 0.10.4 → 0.11.0, `lefthook` 2.1.12 → 2.1.17, `mcp` 1.5.1 → 1.7.0, `mvpa-css` (git c2ce765 → 412cc74), `selenium-webdriver` 4.48.0 → 4.50.0, `solid_cable` 4.0.2 → 4.1.0, `thruster` 0.1.26 → 0.1.27. Transitive: `et-orbi`, `fugit`, `io-console`, `jwt`, `marcel`, `net-imap`, `net-protocol`, `net-smtp`, `net-ssh`, `okcomputer`, `parallel`, `rdoc`, `regexp_parser`, `rubocop-minitest`, `rubocop-rails`, `rubyzip`, `unicode-display_width`, `unicode-emoji`.
- Every transitive constraint in `Gemfile.lock` allows the latest release, except `marcel ~> 1.0` (from `activestorage`).
- Ruby 4.0.7 is installed under `~/.local/share/rv/rubies/ruby-4.0.7`. Its default Bundler is 4.0.20. Gems live inside each Ruby's own gem directory, so Ruby 4.0.7 needs its own `bundle install`.
- Yarn is 1.22.22 (classic). `package.json` pins `@herb-tools/linter` at `^0.10.4`.
- `.github/workflows/ci.yml` uses `actions/checkout@v7.0.1` (latest), `actions/setup-node@v7` (latest is v7.0.0), `spinel-coop/setup-rv@main` and `eirvandelden/appkit/...rails-ci.yml@main`.

## Design decisions

- **Named gem updates, never a bare `bundle update`.** Rule 11 forbids updating all gems without explicit instruction, and Bundler 4 refuses a bare `bundle update` without `--all`. Each commit names its gems. The end state equals "everything except `marcel`".
- **Ruby first, then Bundler, then gems.** Gems then resolve and install under the final Ruby and Bundler. The `bundle outdated` acceptance check also runs under Bundler 4.0.22, which reports "out-of-cooldown" versions.
- **Adopt the new herb 0.11 rules (Etienne, 2026-10-06).** herb version-gates its rules on `.herb.yml`'s `version:` (now `0.10.3`). Bump it to `0.11.0`, fix every new offense in `app/views`, and disable no rule. Upgrading the tool and adopting its rules are two commits, so each commit keeps the linter green.
- **Include solid_cable's channel index removal (Etienne, 2026-10-06).** solid_cable 4.1 looks messages up by `channel_hash` and no longer uses the `channel` index. Its `solid_cable:update` generator copies two migrations: `create_compact_channel` (already in `db/cable_schema.rb`, so it must not run again) and `remove_channel_index`. Write only the second one, by hand, with `bin/rails generate migration RemoveChannelIndexFromSolidCableMessages --database cable`. Its body copies the gem's template: `remove_index :solid_cable_messages, :channel, if_exists: true` up, `add_index ... if_not_exists: true` down. This removes an index, not a table or column (rule 9), and Etienne asked for it.
- **Verify the image locally (Etienne, 2026-10-06).** Run `docker build --platform linux/amd64` once at the end. `config/deploy.yml` builds `amd64`, so the local build matches production. No push, no deploy.
- **Guard the Ruby pin with a test.** The Dockerfile comment says its `RUBY_VERSION` must match `.ruby-version`, but nothing enforces it. A new test in `test/configuration_test.rb` compares the Dockerfile's `ARG RUBY_VERSION` and `Gemfile.lock`'s `RUBY VERSION` (major.minor.patch, patchlevel ignored) with the running `RUBY_VERSION`. The Gemfile's `ruby file: ".ruby-version"` already ties the running Ruby to `.ruby-version`.
- **Fix, never silence.** New RuboCop offenses (`rubocop-eirvandelden` sets `NewCops: enable`, so new `rubocop-rails` 2.38 and `rubocop-minitest` 0.41 cops switch on), new Brakeman 8.1 warnings and new herb offenses are fixed in code. No disable comment, no new `config/brakeman.ignore` entry, no disabled rule. If a finding looks like a false positive, stop and ask Etienne.

## Integration points

- `/mcp` (`AssistantController`, `app/tools/assistant/*`): uses `MCP::Server::Transports::StreamableHTTPTransport` in stateless JSON mode, no OAuth, no icons, no `subscriptions/listen`. mcp 1.6–1.7 changes OAuth, icon validation and listen streams, and bounds the `initialize` request a session retains. A stateless transport retains no session, so no change is expected; `test/integration/assistant_test.rb` proves it.
- Production image: `Dockerfile` `ARG RUBY_VERSION`; the `ruby:4.0.7-slim` image ships Bundler 4.0.20 and must auto-switch to the locked 4.0.22 during `bundle lock --add-platform x86_64-linux` and `bundle install` under `BUNDLE_DEPLOYMENT=1`.
- Production boot: `bin/start-app` runs `bin/rails db:prepare`, which migrates the cable database (`migrations_paths: db/cable_migrate`) on the next deploy.
- CI: appkit's reusable `rails-ci.yml` runs `spinel-coop/setup-rv@main` with `ruby-version: current`, which reads `.ruby-version`. The `lint_erb` job runs `yarn install --frozen-lockfile`, so `yarn.lock` must match `package.json`.
- lefthook pre-commit (rubocop, herb on staged files) and pre-push (rubocop, herb, brakeman, bundler-audit, tests).

## Files that change

- `test/configuration_test.rb` — new test: the production image and the lockfile pin the Ruby the tests run on.
- `.ruby-version` — `4.0.6` → `4.0.7`.
- `Dockerfile` — `ARG RUBY_VERSION=4.0.7`. Nothing else in the file (rule 13).
- `Gemfile.lock` — `RUBY VERSION` `ruby 4.0.7` (Bundler 4 drops the patchlevel), `BUNDLED WITH 4.0.22`, every outdated gem except `marcel`. Bundler 4 also reformats the lockfile slightly.
- `package.json`, `yarn.lock` — `@herb-tools/linter` `^0.11.0`.
- `.herb.yml` — `version: 0.11.0`.
- `app/views/**/*.html.erb` — fixes for new herb 0.11 offenses only (unknown until the linter runs).
- `db/cable_migrate/<timestamp>_remove_channel_index_from_solid_cable_messages.rb` — new migration.
- `db/cable_schema.rb` — regenerated: the `index_solid_cable_messages_on_channel` line goes, the version moves to the migration's timestamp.
- Ruby files flagged by new RuboCop cops or Brakeman checks — fixes only (unknown until the tools run).
- `.github/workflows/ci.yml` — only if a newer action release exists at implementation time. On 2026-10-06 none does.
- `Gemfile` — no change. No gem, npm package or action is added or removed.

## Order of work

Before step 1, capture the baseline on the untouched branch under Ruby 4.0.6: run `bin/rails test 2>&1` and `bin/rails test:system 2>&1`, and save each output to the session scratchpad. Step 9 compares against it.

1. Add the test "the production image and the lockfile pin the Ruby the tests run on" to `test/configuration_test.rb`. Run it under 4.0.6: it passes. Set `.ruby-version` to `4.0.7`. Confirm `ruby -v` in the worktree reports 4.0.7; if not, stop and report (rule 8). Run `bundle install`. Run the test again and watch it fail on the Dockerfile (and on the lockfile, unless `bundle install` already rewrote it).
2. Set the Dockerfile's `ARG RUBY_VERSION=4.0.7`. Run `bundle update --ruby` if the lockfile still says 4.0.6. The test passes. Run `bin/rails test`. Commit: `chore(deps): run on Ruby 4.0.7`.
3. Run `gem install bundler -v 4.0.22` under Ruby 4.0.7 (approved in the intent). Check `bundle help update` for the flag, then run `bundle update --bundler=4.0.22`. Confirm `bundle -v` prints 4.0.22, then run `bundle install` and `bundle lock` until the lockfile stops changing. Run `bin/rails test`. Commit: `chore(deps): bundle with Bundler 4.0.22`.
4. `bundle update mcp`. Run `bin/rails test test/integration/assistant_test.rb`, then `bin/rails test`. Commit.
5. `bundle update solid_cable`. Run `bin/rails test test/configuration_test.rb`, then `bin/rails test`. Commit. Then the index migration:
   - Copy the main checkout's development databases into the worktree with the `using-sqlite-worktrees` skill (the worktree has none).
   - Run `bin/rails db:migrate:status:cable` (rule 9), generate the migration (see Design decisions), and run `bin/rails db:migrate:cable`.
   - Run `bin/rails db:migrate:redo:cable` once to prove `down` works.
   - Confirm `db/cable_schema.rb` lost only the `channel` index and changed its version.
   - Commit the migration and the schema: `chore(cable): drop the channel index solid_cable no longer reads`.
6. `bundle update appkit mvpa-css` (both changed only dev files upstream: lefthook config, CI, cspell removal). Run `bin/rails test`. Commit. Then `bundle update thruster`, run `bin/rails test`, commit.
7. herb, in two commits:
   - `bundle update herb` and `yarn add --dev @herb-tools/linter@^0.11.0`. Run `npx @herb-tools/linter app/views/` with `.herb.yml` still at 0.10.3; it stays green. Commit.
   - Set `.herb.yml` `version: 0.11.0`. Run the linter. Fix every offense in `app/views`, then run `bin/rails test` and `bin/rails test:system`, because markup changes can move what system tests click. Commit: `style(views): adopt herb 0.11 rules`.
8. Lint and test tooling, then the rest. For each group: update it, run the narrowest check, fix what it flags, run `bin/rails test`, commit.
   - `bundle update brakeman` — run `bundle exec brakeman --no-pager -q`.
   - `bundle update rubocop-rails rubocop-minitest parallel regexp_parser unicode-display_width unicode-emoji` — run `bundle exec rubocop`.
   - `bundle update lefthook` — run `bundle exec lefthook run pre-commit --all-files` to confirm the hooks still load.
   - `bundle update selenium-webdriver rubyzip` — run `bin/rails test:system`.
   - `bundle update et-orbi fugit io-console jwt net-imap net-protocol net-smtp net-ssh okcomputer rdoc` — run `bin/rails test`.
9. Verify everything:
   - Run `bundle outdated`: it lists only `marcel`. Any other line means a newer release came out; update it the same way.
   - Run `yarn outdated`: it lists nothing.
   - Run `gh release list -R actions/checkout --limit 3` and the same for `actions/setup-node`. Bump `ci.yml` only if a newer release exists, in its own commit.
   - Run `bin/rails test 2>&1` and `bin/rails test:system 2>&1`. Diff their warnings and deprecations against the baseline. Fix any new warning that an updated gem causes in app code or config. If a warning comes from inside a gem and the app cannot change it, stop and ask Etienne.
   - Run all linters: `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check --update`, and `bundle exec i18n-tasks normalize` (then confirm `git status` shows no locale change).
   - Run `docker build --platform linux/amd64 -t journal-administration:update-dependencies .`. It must finish, and the build log must show Bundler 4.0.22. If amd64 emulation is unavailable, build the native platform and report that difference. Remove the image afterwards.
10. Re-read the full diff against `main` (rule 21), then hand over to review. Push with the worktree's `bin/` first on `PATH` (`PATH="$PWD/bin:$PATH" git push`), so the pre-push hooks boot this worktree's app.

## Risks

- **Bundler 4 in the image.** `bundle lock --add-platform` runs under `BUNDLE_DEPLOYMENT=1` and must auto-switch from 4.0.20 to 4.0.22. The local amd64 build in step 9 tests exactly this. If it fails, stop: changing the Dockerfile beyond `RUBY_VERSION` needs Etienne's approval (rule 13).
- **Ruby 4.0.7 gem install.** Native extensions (`sqlite3`, `bcrypt`, `bcrypt_pbkdf`, `nokogiri`) compile or download again for 4.0.7. A compile failure is a toolchain problem: report it, do not fix the toolchain (rule 8).
- **CI Ruby.** `setup-rv` must provide 4.0.7. The PR's CI run proves it; if it cannot, report it rather than pin another version.
- **New lint rules.** herb 0.11 (once the version moves), new RuboCop cops and Brakeman 8.1 can each flag existing code. The fixes can grow the diff; keep each fix in the commit of the tool that asked for it.
- **Cable migration.** It runs on the next deploy through `db:prepare`. It only removes an index, with `if_exists: true`, so a missing index cannot fail it. During the migration, SQLite briefly locks the cable database, which can delay live updates for a moment.
- **Lockfile churn.** Bundler 4 drops the patchlevel and changes lockfile spacing. This is expected noise in step 3, not an unrelated change.
- **Rejected:** a bare `bundle update` / `bundle update --all` (rule 11, and it hides which commit moved what); merging the six Dependabot PRs one by one (some already lag newer releases); running the `solid_cable:update` generator as is (it would also copy `create_compact_channel`, which the schema already contains); keeping `.herb.yml` at 0.10.3 (Etienne chose to adopt the rules).

## Out of scope

- `marcel` 2.x, held at 1.x by `activestorage ~> 1.0`.
- Version constraints in `Gemfile`.
- Closing the Dependabot PRs #331, #332, #333, #338, #339, #340; Dependabot closes them itself.
- Deploying (rule 13), and any Dockerfile or `config/deploy.yml` change beyond `RUBY_VERSION`.
- Installing or switching any tool other than Bundler 4.0.22.
- appkit's own reusable workflow still pins `actions/checkout@v6.0.3` and `actions/setup-node@v6`. That file lives in the appkit repository; propose it there as a separate change.
- solid_cable 4.1's optional encryption (`encrypt: true`) and its new batching or trimming settings.

## Proof

- `bundle outdated` lists only `marcel` → command `bundle outdated`, run in step 9.
- `yarn outdated` lists nothing → command `yarn outdated`, run in step 9.
- `.ruby-version`, Dockerfile `RUBY_VERSION` and `Gemfile.lock` `RUBY VERSION` all say 4.0.7 → `test/configuration_test.rb` `the production image and the lockfile pin the Ruby the tests run on`, run under Ruby 4.0.7 (`ruby -v`).
- `Gemfile.lock` says `BUNDLED WITH 4.0.22` → `bundle -v` prints `Bundler version 4.0.22`, and `grep -A1 "BUNDLED WITH" Gemfile.lock`.
- Every action points at its latest release → `gh release list` for `actions/checkout` and `actions/setup-node`, compared with `.github/workflows/ci.yml`.
- `bin/rails test` and the system tests pass → `bin/rails test`, `bin/rails test:system`.
- Linters pass → `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check --update`, `bundle exec i18n-tasks normalize` with a clean `git status`.
- No new deprecation warning from an updated gem → the diff of step 9's test output against the baseline shows none.
- The assistant can still list transactions through `/mcp` → `test/integration/assistant_test.rb` `the assistant finds the transactions that still need a category` (and the whole file passes).

Per changed file, the unit tests expected, named as behaviour:

- `test/configuration_test.rb`: `the production image and the lockfile pin the Ruby the tests run on`.
- `app/views/**` herb fixes: no new tests; the existing controller and system tests cover the rendered pages.
- `db/cable_migrate/*_remove_channel_index_from_solid_cable_messages.rb`: no unit test (the test environment has no cable database); proven by `db:migrate:cable`, one `db:migrate:redo:cable`, and the `db/cable_schema.rb` diff.

Test setup: no new fixtures. The new configuration test reads `Dockerfile` and `Gemfile.lock` from `Rails.root` (for the lockfile, `Bundler::LockfileParser`) and compares major.minor.patch with `RUBY_VERSION`. The step 5 migration needs development databases in the worktree, copied with the `using-sqlite-worktrees` skill.

---
Domain skills applied: dependencies. Named for the implementer: using-sqlite-worktrees (step 5).

## Implementation notes

- herb 0.11's `html-no-nested-forms` flagged `form_with` inside `turbo_frame_tag` in `app/views/budgets/_form.html.erb`. This is a false positive: herb mistakes `turbo_frame_tag` for a form. The view now uses the literal `<turbo-frame>` tag, which renders the same HTML. Etienne chose to follow the latest herb rules this way (2026-10-11). `test/integration/budgets_test.rb` guards the frame's id and `target="_top"`.
- Version bumps not named in the plan: `rubocop` 1.92 (with the rubocop-rails group), and `uri` 1.1.2 and `prettyprint` 0.2.1 (resolved in the solid_cable commit).
- Bundler 4 keeps the patchlevel: the lockfile says `ruby 4.0.7p0`, not `ruby 4.0.7` as the plan expected. The guard test in `test/configuration_test.rb` accepts both forms.
- Newer releases appeared during implementation: `selenium-webdriver` 4.51.0, `lefthook` 2.2.1, `date` 3.6.0. The branch carries them.
- `docker build --platform linux/amd64` first failed in `apt-get` with "not enough free space" inside the Rancher Desktop VM. After a build-cache prune (2026-10-11) it succeeds on `ruby:4.0.7-slim`. The image boots Rails 8.1.4 on Ruby 4.0.7.
- Bundler does not switch versions inside the image: it runs the image's default 4.0.20 against `BUNDLED WITH 4.0.22`. Install and boot still work. Pinning 4.0.22 in the image needs a Dockerfile change beyond `RUBY_VERSION` (rule 13), so it is left as is.
- `bin/rails test:system` is left to CI, by Etienne's choice (2026-10-11).
- `bin/rails test:system` errors on the untouched branch too: ChromeDriver wants Chrome 155, the cached Chrome for Testing is 150. This is a toolchain issue, not fixed here.

## Amendment (2026-10-11)

Status: accepted.

1. Bundler in the image. In the Dockerfile build stage, after `COPY Gemfile Gemfile.lock .ruby-version ./` and before `bundle lock`, add `RUN gem install bundler --no-document -v "$(awk '/BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)"`. The version comes from the lockfile, so a later Bundler bump needs no Dockerfile edit. The official image sets `GEM_HOME=/usr/local/bundle`, the same as `BUNDLE_PATH`, so the existing `COPY --from=build "${BUNDLE_PATH}"` carries the gem into the final stage. Verify the `GEM_HOME` value in the image before relying on it. Commit: `build(docker): install the Bundler the lockfile names`.
2. herb framework. Add `framework: actionview` to `.herb.yml`, below `version:`. Run `npx @herb-tools/linter app/views/`. Fix each new offense in the view, then run `bin/rails test`. Commit: `style(views): lint templates as Action View`.
3. Verify: `docker build --platform linux/amd64`, then `docker run --rm --entrypoint sh <image> -c 'bundle -v; bundle exec ruby -e "puts Bundler::VERSION"; SECRET_KEY_BASE_DUMMY=1 bin/rails runner "puts Rails.version"'`. Both Bundler lines print 4.0.22 and Rails boots. Remove the image. Prune only the build cache if space runs out. Push with the worktree `bin/` and Ruby 4.0.7 first on `PATH`.

Proof: the `docker run` output above; herb's summary with no failing offense and no framework notice; `bin/rails test` green. No new unit test: neither change alters app behaviour, and the image check exercises the Dockerfile directly.

### Amendment notes

- The image now installs Bundler 4.0.22 from the lockfile. In the amd64 build, `bundle -v` and `bundle exec` both report 4.0.22, and Rails 8.1.4 boots.
- `framework: actionview` enabled 40 info and hint offenses, none failing. Etienne chose to fix all 40 here (2026-10-12), one commit per rule: qualified partial paths, explicit route helpers, explicit partials, the `label` local that shadowed the helper, and `form_for` → `form_with`.
- STI transactions keep their `/credit/:id`, `/debit/:id` and `/transfer/:id` links through `polymorphic_path`, which herb accepts. `transaction_path` would have changed those URLs.
- New tests guard each rewrite: transaction links by kind, search results by type, account aliases, the users index, the budget percentage label, and what each of the six record forms submits. The form tests pass on both the `form_for` and the `form_with` views.

### Refresh notes (2026-10-21)

- The branch is rebased onto `main` after #343, #345 and #349. #349 replaced yarn with npm, so the herb linter bump now lives in `package-lock.json`, and `npm outdated` replaces `yarn outdated` as the check.
- The people and group views from #345 had 6 Action View offenses. They now use `person_path`, `group_path` and qualified form partials, and their index tests check the link targets.
- Review round 2 and 3 nits are closed: the search `case` raises on a result type without a partial, and the credit edit-link test moved to `transactions_show_test.rb`.
- Newer releases since 2026-10-11: `lefthook` 2.2.2, `herb` and `@herb-tools/linter` 0.11.1, `sqlite3` 2.10.1, `json` 3.1.0, `net-imap` 0.6.8, `mcp` 1.8.0, `mvpa-css` 2be440b, `rubocop-capybara` 3.1.0 and `rubocop-eirvandelden` 6d41c35. The last brings `rubocop-rbs_inline` 2.0.0 and `rbs-inline` 0.14.0 as its own dependencies; the Gemfile does not change.
- `.herb.yml` moves to 0.11.1, which turns on `actionview-no-local-assigns` and `erb-require-template-format`. One offense, in `transaction_splits/_table.html.erb`, is fixed.
- `net-ssh` 8.0.0 stays out: kamal 2.12.0 requires `net-ssh ~> 7.3`. `marcel` stays on 1.x for Active Storage, and `appkit` is updated separately.
- The rubocop pre-commit job in the repo's `lefthook.yml` fails inside `git commit` in a worktree: git exports `GIT_DIR`, and Bundler then cannot load the git-sourced gems. Two test commits went in with `--no-verify` by Etienne's choice (2026-10-20), after rubocop passed on the staged files by hand.
- The budget suggestion system test fails on days a suggested amount ends in 0 (`0.7` against `"0.70"`). Etienne chose to leave it until money moves to cents (2026-10-16).
