# Plan: Replace yarn with npm in personal projects

From `intent.md` (2026-10-17). Status: accepted.

## Design decisions

- One plan, ten phases. Phase 0 is dotfiles, in this worktree. Phases 1–9 are one repo each. Each phase is its own branch `replace-yarn-with-npm` and its own pull request.
- Fan-out to the other repos: for each repo, the coordinator runs `~/.config/git/worktree-tools/worktree-create --no-pane replace-yarn-with-npm` inside that repo. It then copies this folder's `intent.md` and `plan.md` into `<repo>/docs/changes/replace-yarn-with-npm/` and commits them with `commit-plan`. The implement, review and deliver stages then run in that worktree. The implementer of a repo phase does only that repo's section below.
- Order: Phase 0 (dotfiles) merges first. Most personal repos load the dotfiles `lefthook.yml` as a lefthook remote (`remotes: - git_url: git@github.com:eirvandelden/dotfiles`). Today that shared config runs `yarn install` when `package-lock.json` changes, which would recreate a `yarn.lock` in a migrated repo. Phase 1 (appkit) comes next, because its reusable `rails-ci.yml` runs CI for clocky, happiness, journal_administration and sticker-app. Phases 2–9 follow in any order.
- Generate each `package-lock.json` with `npm install` while `yarn.lock` is still present. npm 7+ reads `yarn.lock` as resolution guidance, so the resolved versions stay those of `yarn.lock`. Step 3 of the order of work proves it over the whole graph, not only direct dependencies. Delete `yarn.lock` after that, then prove the lock with `rm -rf node_modules && npm ci`.
- Linter calls in lefthook files become `npx --no <bin>`. `--no` refuses to fetch a package that is not in the project. Plain `npx` assumes `--yes` without a TTY, which is the case in a git hook, and downloads the newest linter (the known failure in a worktree without `node_modules`). `npx --no` keeps today's behaviour: the hook fails when the tool is not installed.
- The dotfiles `lefthook.yml` stays usable for repos that keep yarn (work repos are out of scope and may load it). Its `client-dependencies` job runs `npm install` when the repo has `package-lock.json`, `yarn install` when it has only `yarn.lock`, and nothing when it has neither lockfile. `npx --no` also works in a yarn v1 repo, because yarn v1 installs into `node_modules/.bin`.
- Package scripts run with `npm run <script>` (`npm run lint:css`). `test` runs with `npm test`.
- Developer installs in `bin/setup` use `npm install` (keeps `node_modules`, updates the lock only when `package.json` changed). CI and the Dockerfile use `npm ci` (exact lock, fails on drift).
- Each Rails repo gets one acceptance test file, `test/lib/javascript_package_manager_test.rb`. It asserts `package-lock.json` exists, `yarn.lock` and `bin/yarn` do not, and `git grep -i -l yarn` over tracked files finds nothing outside the repo's data paths and the test file itself. mvpa.css and dotfiles use their existing plain Minitest layout instead (see their sections).
- Every migrated Rails repo's `bin/setup` installs JavaScript packages with `system!("npm install")` before it prepares the database. Today only cityofbrass installs them; the acceptance criterion covers every migrated Rails repo.
- dm-adventure-book is deferred by default (see its phase). It runs only if Etienne approves the rake override and the `production.rb` edit.
- The yarn ignore entries (`/yarn-error.log`, `yarn-debug.log*`, `.yarn-integrity`) leave each migrated repo's `.gitignore`. Nothing in a migrated repo writes those files any more.

## Integration points

- Lefthook remote config: dotfiles `lefthook.yml` on `main`, loaded by clocky, ddicompendium, journal_administration, mvpa.css and sticker-app.
- GitHub Actions: appkit `.github/workflows/rails-ci.yml` (reusable, called by clocky, happiness, journal_administration and sticker-app; today it installs no JavaScript packages), and each repo's own `.github/workflows/ci.yml`. Editing `ci.yml` in all repos is approved in `intent.md`.
- cityofbrass `Dockerfile` (approved in `intent.md`) and its Kamal image build. No deploy runs.
- The implementer records `node --version` and `npm --version` in each phase's report; they differ per shell and per `.node-version` file. CI uses `actions/setup-node` (node 20, 22, 24 and `lts/*`); every one ships npm 7 or later, which reads lockfile v3.
- Open branches that touch `yarn.lock` (`update-dependencies` worktrees in clocky, ddicompendium, happiness, mvpa.css and sticker-app; dependabot branches) will conflict after these merge. They rebase on their own merits later; this change does not touch them.

## Files that change

### Phase 0 — dotfiles (this worktree)

- `agents/.agents/skills/dependencies/SKILL.md` — "Node: use yarn, not npm." becomes "Node: use npm, not yarn." Keep "Prefer a gem over adding a JavaScript dependency."
- `lefthook.yml` — pre-commit and pre-push `stylelint` run `npx --no stylelint {…}`; `eslint` runs `npx --no eslint {…}`. `client-dependencies` glob stays `{yarn.lock,package-lock.json,package.json}`; its run becomes `: {files}; if [ -f package-lock.json ]; then npm install; elif [ -f yarn.lock ]; then yarn install; fi` (POSIX `[ ]`, never `[[ ]]`: lefthook runs it under `sh -c`).
- `test/lefthook_pull_hooks_test.rb` — stub `npm` as well as `yarn`. Rename `test_changed_package_lock_json_triggers_yarn_install` to `test_changed_package_lock_json_triggers_npm_install`, assert `npm install`, refute `yarn install`. Add `test_changed_package_json_beside_package_lock_triggers_npm_install`, `test_changed_package_json_beside_yarn_lock_triggers_yarn_install` and `test_changed_package_json_without_lockfile_installs_nothing`. Add `npm install` to the readme-only refute list.
- `test/lefthook_local_hooks_test.rb` (or a new `test/lefthook_node_linters_test.rb` if the existing harness cannot stub per command) — a staged `.css` file runs `npx --no stylelint`, a staged `.js` file runs `npx --no eslint`; stub `npx` to log its arguments.
- Unchanged on purpose: `git/.config/git/hooks/*` (lefthook-generated shims; `yarn lefthook` is one of its generic runner fallbacks), `git/.config/git/ignore.global` and `packages.conf` (the global `yarn` stays for work repos), `claude/.claude/settings.json` (`registry.yarnpkg.com` stays for work repos), vendored `rails-guides` references (third-party text), `test/lefthook_global_hooks_sync_test.rb` (it pushes `yarn.lock` and expects `yarn install`, which the yarn-only rule keeps).

### Phase 1 — appkit

- `lefthook.yml` — `yarn stylelint` and `yarn eslint` (pre-commit and pre-push) become `npx --no stylelint` and `npx --no eslint`. `client-dependencies` glob becomes `{package-lock.json,package.json}` and runs `npm install`.
- `.github/workflows/rails-ci.yml` — the test job (it already runs `actions/setup-node`) gets a step `Install JavaScript packages` that runs `if [ -f package-lock.json ]; then npm ci; fi`, before the tests. No `cache: npm`: setup-node fails on a cache key when the calling repo has no lockfile.
- No lockfile and no `bin/yarn` in appkit itself.
- Proof: appkit has no lefthook test. Add `test/lefthook_config_test.rb` beside `test/dependabot_config_test.rb` (same style; `rake test` runs `test/**/*_test.rb`). It loads `lefthook.yml` with `YAML.safe_load_file` and asserts no `run:` calls yarn and the linter jobs use `npx --no`. Add `test/rails_ci_workflow_test.rb` in the same style: the test job runs `npm ci` when `package-lock.json` exists, before the test step.

### Phase 2 — cityofbrass

- `yarn.lock` → removed; `package-lock.json` → added (generated as above).
- `bin/yarn` → removed (Rails 8.1 has no `yarn:install` task that needs it).
- `bin/setup` — `system!("yarn install --check-files")` becomes `system!("npm install")`.
- `.github/workflows/ci.yml` — the two-line install step becomes `npm ci`; add `cache: npm` to the existing `setup-node` block.
- `Dockerfile` — `RUN npm install --global yarn && yarn install --frozen-lockfile` becomes `RUN npm ci`, still before `assets:precompile`.
- `test/bin/setup_test.rb` — match `system!` with `npm install`; positions use `"npm install"`.
- `test/lib/dockerfile_assets_test.rb` — look for `"npm ci"`; messages say npm.
- `test/lib/javascript_package_manager_test.rb` — new. Data paths excluded: `db/seeds/` (creature text "Yarnspinner").

### Phase 3 — clocky

- `yarn.lock` → removed; `package-lock.json` → added.
- `bin/setup` — add `system!("npm install")` before `bin/rails db:prepare`.
- `lefthook-local.yml` — comment "No yarn toolchain in this app" becomes "No npm toolchain in this app"; the skips stay.
- `.gitignore` — remove yarn entries if present.
- `test/lib/javascript_package_manager_test.rb` — new.

### Phase 4 — ddicompendium

- `yarn.lock` → removed. `package-lock.json` already exists and CI already runs `npm ci`. First check `npm ci` against it; if it fails, regenerate it with `npm install` while `yarn.lock` is still present.
- `bin/yarn` → removed.
- `bin/update` — drop the two commented yarn lines.
- `bin/setup` — add `system!("npm install")` before `bin/rails db:prepare`.
- `.gitignore` — remove `/yarn-error.log`.
- `test/lib/javascript_package_manager_test.rb` — new. Data paths excluded: `lib/ddi_sql_files/` ("Yarnath's Glyph").

### Phase 5 — dm-adventure-book (deferred until Etienne decides)

- Rails 5.2 and webpacker 3.5.5 call yarn themselves: `assets:precompile` enhances `yarn:install`, which runs `./bin/yarn install`; webpacker's initializer runs `yarn check --integrity` when `check_yarn_integrity` is true and `yarn.lock` exists.
- Default: skip this phase. The repo keeps yarn and the coordinator reports it as deferred.
- Proposed, if Etienne approves: `yarn.lock` → removed, `package-lock.json` → added; `bin/yarn` → removed; new `lib/tasks/javascript.rake` clears the `yarn:install` task and redefines it to run `npm install` (the task name is fixed by railties and webpacker, so the file names `yarn` once); `config/environments/development.rb` loses `check_yarn_integrity`; `config/environments/production.rb` loses `check_yarn_integrity = false` (rule 13: needs approval); `config/initializers/assets.rb` comment says node_modules; `bin/setup` replaces the commented yarn lines with `system! 'npm install'`; `bin/update` loses its commented yarn lines; `.gitignore` loses the yarn entries; `test/lib/javascript_package_manager_test.rb` excludes `lib/tasks/javascript.rake`.
- No CI workflow exists in this repo.

### Phase 6 — happiness

- `yarn.lock` → removed; `package-lock.json` → added.
- `lefthook.yml` — `yarn stylelint` → `npx --no stylelint`, `yarn eslint` → `npx --no eslint`, `yarn test` → `npm test`; `client-dependencies` glob `{package-lock.json,package.json}`, run `npm install`.
- `config/ci.rb` — `"yarn test"` → `"npm test"`.
- `bin/setup` — add `system!("npm install")` before `bin/rails db:prepare`.
- `AGENTS.md` — `yarn test` → `npm test`; `yarn eslint .` → `npx eslint .`; `yarn stylelint` → `npm run stylelint`.
- `.gitignore` — remove both blocks of yarn entries.
- `test/lib/javascript_package_manager_test.rb` — new.

### Phase 7 — journal_administration

- `yarn.lock` → removed; `package-lock.json` → added.
- `.github/workflows/ci.yml` — `cache: yarn` → `cache: npm`; `yarn install --frozen-lockfile` → `npm ci`; `yarn run herb-lint …` → `npx --no herb-lint …`.
- `.lefthook.yml` — `yarn run herb-lint` (two runs and the `fail_text`) → `npx --no herb-lint`.
- `AGENTS.md` — "until `yarn install` runs there" → "until `npm install` runs there".
- `bin/setup` — add `system!("npm install")` before `bin/rails db:prepare`.
- `.cspell.yml` — remove the `yarn-error.log` ignore entry. `.gitignore` — remove both yarn blocks.
- `test/lib/javascript_package_manager_test.rb` — new.

### Phase 8 — mvpa.css

- `yarn.lock` → removed; `package-lock.json` → added. The gemspec ships only `{app,config,lib}/**/*` and docs, so neither lockfile is in the gem.
- `.github/workflows/ci.yml` — `cache: yarn` → `cache: npm`; `yarn install --frozen-lockfile` → `npm ci`; `yarn lint:browsers` → `npm run lint:browsers`; `yarn lint:css` → `npm run lint:css`.
- `test/continuous_integration_test.rb` — `workflow_scripts` scans `/npm run (lint:[\w:-]+)/`; the message in `test_the_workflow_only_runs_scripts_that_exist` says ``CI runs `npm run #{script}` ``. Add `test_package_lock_replaces_yarn_lock` and `test_no_tracked_file_names_yarn` (this repo uses plain Minitest under `rake test`).
- `AGENTS.md` — `yarn install` → `npm install`; `yarn lint:css` → `npm run lint:css`; `yarn lint:browsers` → `npm run lint:browsers`.
- `README.md` — "Run the CSS linter with Yarn:" → "with npm:"; `yarn lint:css` → `npm run lint:css`.

### Phase 9 — sticker-app

- `yarn.lock` → removed; `package-lock.json` → added.
- `.github/workflows/ci.yml` — `yarn install --frozen-lockfile` → `npm ci`; add `cache: npm` to its `setup-node` block.
- `bin/setup` — add `system!("npm install")` before `bin/rails db:prepare`.
- `lefthook-local.yml` — comment "No package.json/yarn toolchain" → "No stylesheet toolchain in this app"; the skips stay.
- `.gitignore` — remove both yarn blocks.
- `test/lib/javascript_package_manager_test.rb` — new.

## Order of work

Per phase, in that phase's worktree:

1. Write the acceptance test (the new `javascript_package_manager_test.rb`, or the phase's named test changes), run it, watch it fail for the yarn reason.
2. Update the tests that assert yarn commands (cityofbrass, mvpa.css, dotfiles); run them; watch them fail.
3. Run `npm install` with `yarn.lock` present; check `git diff --stat` shows only `package-lock.json` added (no `package.json` change). Compare the full resolved graph: every `name@version` in `package-lock.json` `packages` must appear in `yarn.lock`. A missing pair (direct or transitive) stops the phase with a `Decision needed:` line that lists the pairs. Delete `yarn.lock` and `bin/yarn`.
4. `rm -rf node_modules && npm ci`; it must succeed.
5. Edit the remaining files in the phase list; run the tests until green.
6. Run `bin/setup --skip-server` (dm-adventure-book: `bin/setup`) and confirm it runs `npm install`.
7. Run every script CI runs, locally, with npm (`npm run lint:css`, `npx herb-lint …`, `npm test`), the full test suite, the repo's linters (rubocop, yamllint where present), Brakeman and Bundler Audit where the repo has them.
8. Search: `git grep -n -i yarn` must list only the phase's excluded data paths and its own test file.
9. Commit in small steps (lockfile swap; CI and Docker; scripts and hooks; docs), push, then review and deliver. CI must be green on the pull request.

Phase 0 runs first and merges before Phases 2–9 push. Phase 1 merges before the four repos that call `rails-ci.yml`.

## Risks

- A repo with a `package.json` and no lockfile gets no automatic install after a pull any more. Accepted: guessing the package manager there could switch a yarn project to npm.
- A yarn v2+ (Plug'n'Play) repo has no `node_modules/.bin`, so `npx --no stylelint` fails there. No personal repo uses PnP; work repos are out of scope.
- `npm install` may resolve a range differently from `yarn.lock` when npm cannot map a yarn entry. Step 3 checks the diff; a version change in `package-lock.json` versus `yarn.lock` for a direct dependency stops the phase.
- dm-adventure-book: removing `bin/yarn` without the rake override breaks `assets:precompile`. Its suite runs on Ruby 3.1.7 (`.ruby-version`); if that Ruby is not installed, the phase cannot run tests (rule 8 stops it).
- Rejected: keeping `bin/yarn` as an npm wrapper (still a yarn name, misleading); `npx` without `--no` (downloads tools in hooks); `npm ci` in `bin/setup` (deletes `node_modules` on every run); removing the global `yarn` from `packages.conf` (work repos need it, and rule 8).

## Out of scope

- Work repos and `dotfiles-work`; the qmk_firmware fork and other upstream forks.
- Vendored third-party text (Rails guides) and lefthook-generated hook shims.
- Node or package upgrades; adding or removing any dependency.
- Rebasing the open `update-dependencies` and dependabot branches.
- Any deploy.

## Proof

- Installing in a migrated repo with `npm ci` succeeds and uses `package-lock.json` → each repo's `test/lib/javascript_package_manager_test.rb` `uses package-lock.json` (mvpa.css: `test/continuous_integration_test.rb` `test_package_lock_replaces_yarn_lock`), plus the step 4 `npm ci` run and the CI install step.
- A migrated repo has no `yarn.lock` and no `bin/yarn` → `test/lib/javascript_package_manager_test.rb` `has no yarn lockfile` and `has no bin/yarn`.
- A migrated repo's CI runs `npm ci` and its lint and test scripts with npm, and CI is green → cityofbrass `test/lib/dockerfile_assets_test.rb` `docker build installs javascript dependencies before precompiling assets`; mvpa.css `test/continuous_integration_test.rb` `test_the_workflow_only_runs_scripts_that_exist` (over the `npm run` scan); appkit `test/lefthook_config_test.rb`; then `gh pr checks` green on each pull request.
- Running `bin/setup` in a migrated Rails repo installs JavaScript packages with npm → cityofbrass `test/bin/setup_test.rb` `a failed JavaScript install stops the setup` and `installs JavaScript dependencies before preparing the database`; every other Rails repo `test/lib/javascript_package_manager_test.rb` `bin/setup installs JavaScript packages with npm before preparing the database`; check: `bin/setup --skip-server` output shows `npm install`.
- The repo's tests and linters pass as before the change → check: full suite, rubocop, yamllint, Brakeman, Bundler Audit per repo, and CI.
- A search of a migrated repo for `yarn` (excluding fixtures and data) finds nothing → `test/lib/javascript_package_manager_test.rb` `names yarn nowhere outside data`; mvpa.css `test/continuous_integration_test.rb` `test_no_tracked_file_names_yarn`.
- The dotfiles `dependencies` skill says to use npm, not yarn → check: `grep -n "use npm, not yarn" agents/.agents/skills/dependencies/SKILL.md`.

Per changed file, the unit tests expected:

- dotfiles `lefthook.yml`: `test_changed_package_lock_json_triggers_npm_install`, `test_changed_package_json_beside_package_lock_triggers_npm_install`, `test_changed_yarn_lock_triggers_yarn_install` (kept), `test_pull_touching_only_readme_runs_no_migrations` (extended with `npm install`), `test_pre_commit_stylelint_runs_through_npx_no`, `test_pre_commit_eslint_runs_through_npx_no`.
- dotfiles `lefthook.yml` (continued): `test_changed_package_json_beside_yarn_lock_triggers_yarn_install`, `test_changed_package_json_without_lockfile_installs_nothing`.
- appkit `lefthook.yml`: `test_no_lefthook_command_calls_yarn`, `test_linters_run_through_npx_no`.
- appkit `.github/workflows/rails-ci.yml`: `test_test_job_installs_javascript_packages_with_npm_ci`.
- Each Rails repo's `bin/setup` (not cityofbrass): `bin/setup installs JavaScript packages with npm before preparing the database`.
- cityofbrass `bin/setup`, `Dockerfile`: the two existing setup tests and the Dockerfile test, rewritten for npm.
- mvpa.css `.github/workflows/ci.yml`: `test_the_workflow_only_runs_scripts_that_exist` (existing, over `npm run`); `test_package_lock_replaces_yarn_lock`; `test_no_tracked_file_names_yarn`.

Test setup: dotfiles lefthook tests reuse the stub-command harness (log-writing shell stubs on `PATH`, add `npm` and `npx`). Repo tests read tracked files only (`git ls-files`, `git grep`); no fixtures, no network.

---
Domain skills applied: dependencies, rails-testing, dotfiles-maintenance.

## Critique

### Round 1 (codex terra)

- appkit's reusable `rails-ci.yml` stays unchanged, so clocky and happiness CI never runs `npm ci` → fixed (Phase 1 adds a conditional `npm ci` step to the test job, with `test/rails_ci_workflow_test.rb`)
- dm-adventure-book `bin/setup` only loses commented yarn lines and still installs no JavaScript packages → fixed (every migrated Rails repo's `bin/setup` now runs `npm install`, with a test per repo)
- The dm-adventure-book `yarn:install` override conflicts with the "no yarn outside data" criterion → fixed (the phase is deferred by default and goes to Etienne as a decision)
- The shared hook runs `npm install` when no lockfile exists, which can switch a lockless yarn project → fixed (npm only with `package-lock.json`, yarn only with `yarn.lock`, nothing otherwise; new test for the lockless case)
- The node and npm versions in the plan do not match the critic's shell → fixed (the implementer records the versions per phase instead)
- Step 3 checks only direct dependency versions → fixed (step 3 compares every `name@version` in `package-lock.json` against `yarn.lock`)

## Decisions recorded (Etienne, 2026-10-17)

- dm-adventure-book stays on yarn. Skip its phase; do not edit `config/environments/production.rb`.
- The coordinator may fan out `intent.md` and `plan.md` into the other repos, one repo at a time.
