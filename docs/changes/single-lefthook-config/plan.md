# Plan: One lefthook config that builds on the dotfiles defaults

From `intent.md` (2026-10-16). Status: accepted.

## Context

The global hook shim in `~/.config/git/hooks/*` sets `LEFTHOOK_CONFIG` to `~/Developer/dotfiles/lefthook.yml` only when the repository has no `lefthook.yml`, `.lefthook.yml` or `.config/lefthook.yml`. This repository has `lefthook.yml` and `.lefthook.yml`, so the dotfiles `post-merge`, `post-rewrite` and `migrations` sections never load here.

Facts checked on 2026-10-16. Inside this repository both `bin/lefthook` and the `lefthook` on `PATH` run 2.1.12, the `Gemfile.lock` version:

- Today `lefthook dump` in this repository shows only `lefthook.yml`. Lefthook ignores `.lefthook.yml` when `lefthook.yml` exists. So `herb-lint`, `herb-analyze` and `i18n-normalized` do not run today, and the `remotes:` entry in `.lefthook.yml` has no effect.
- `extends:` does not expand `~` or `$HOME`. An absolute path works, and so does a glob such as `/Users/*/Developer/dotfiles/lefthook.yml`.
- An `extends:` path or glob that matches no file is ignored silently. The config still loads.
- The extended file wins over the main file, field by field. A repository command with the same name as a dotfiles command gets the dotfiles `run`. A field that only the repository sets, such as `skip: true` or `exclude:`, survives the merge. Checked in a scratch repository: a repository `yamllint` entry with `run: "true"` and `exclude: ["config/locales/**"]` dumps as the dotfiles `yamllint {staged_files}` with that `exclude`, and a staged locale file with bad indentation then passes; without the `exclude` it fails.
- A command with `skip: true` or `exclude:` and no `run` makes `lefthook run` exit 1 with "either `run`, `script`, or `group` must be provided" when the extended file is absent. A stub with `run: "true"` is valid in both cases.

Linter state on 2026-10-16, measured with the five approved packages installed in a scratch directory:

- `stylelint-config-standard` flags 14 errors in 4 files. `--fix` corrects 5 of them at 3 places: an empty line between `@import` rules (`application.css`), `min-width` range notation (`local/layout/application_page.css`), and the `rgba(0, 0, 0, 0.2)` value (`local/modules/search_dialog.css`, three rules on one value). The other 9 are `selector-class-pattern` on 6 `.field_with_errors` selectors and `selector-id-pattern` on 3 `#error_explanation` selectors, all in `local/modules/form_errors.css`.
- `field_with_errors` is the class that Rails `ActionView::Base.field_error_proc` puts around invalid fields; no repository code sets it. `error_explanation` is the Rails scaffold id, used in 6 form partials and asserted in 3 integration tests (`test/integration/product_types_test.rb`, `test/integration/products_test.rb`).
- `@eslint/js` recommended with `globals.browser` and ES modules flags 3 errors: `Turbo` undefined in `app/javascript/application.js:6`, `require` undefined in `app/javascript/channels/index.js:4`, and unused `_error` in `app/javascript/controllers/clipboard_controller.js:16`.
- The vendored `turbo.min.js` from `turbo-rails` ends in `export{Wt as Turbo,Gt as cable}`, so `import { Turbo } from "@hotwired/turbo-rails"` resolves.
- `app/javascript/channels/` is untouched since the Rails 6 initial commit. `config/importmap.rb` does not pin it, and nothing references it, so the browser never loads `channels/index.js`. Its `require.context` is a webpacker call that cannot run under importmap.
- `yamllint` (with the user config in `~/.config/yamllint/config`) exits 1 only on `config/locales/{en,it,nl}.yml`: 15 `indentation` errors, the layout that `i18n-tasks normalize` writes. Every other tracked YAML file gives warnings only, and warnings exit 0.
- `erb_lint` 0.9.0 (default config, no `.erb_lint.yml`) flags one `SpaceInHtmlTag` offence in `app/views/layouts/application.html.erb:7`: the newline before the closing `>` of the multi-line `<html` tag. `erb_lint -a` moves the `>` to the end of line 7, and the file then passes. `app/views/layouts/admin.html.erb:7` has the same offence; the intent names only `application.html.erb` (see Risks).
- The installed versions are `stylelint` 17.16.0, `stylelint-config-standard` 40.0.0, `eslint` 10.13.0, `@eslint/js` 10.0.1, `globals` 17.13.0. Their `engines` accept the repository's Node 22.21.1 (`.node-version`).

## Design decisions

- Load the dotfiles defaults through `extends: [/Users/etienne.vandelden/Developer/dotfiles/lefthook.yml]`, one exact path: the machine the intent names. A missing path is ignored, so a contributor without the dotfiles gets only the repository checks. A comment above it says why the path is exact. Rejected: the glob `/Users/*/Developer/dotfiles/lefthook.yml`. It also matches the world-writable `/Users/Shared` (`drwxrwxrwt`), so another local user could plant a config that the hooks then run. Rejected: adding `/Users/eirvandelden/Developer/dotfiles/lefthook.yml` for a second machine. On this machine `/Users/eirvandelden` exists, is world-writable (`drwxrwxrwx root admin`) and holds no dotfiles, so that path has the same hole. Another machine is a `Decision needed:` line in the report. `remotes:` is rejected: it needs a network fetch and `lefthook install`, and the intent puts the `remotes:` mechanism out of scope.
- The single file is `lefthook.yml`. It is the file lefthook already reads, and the `bin/lefthook` binstub and the docs already point at it. `.lefthook.yml` and `lefthook-local.yml` are deleted.
- Repository commands never reuse a dotfiles command name, because the dotfiles `run` would replace theirs. The repository `rubocop` becomes `rubocop-app` in `pre-commit` and `pre-push`, and `brakeman` becomes `brakeman-app` in `pre-push`. `bundler_audit` and `tests` keep their names; the dotfiles names differ (`bundle-audit`, `minitest`).
- Dotfiles commands that duplicate a repository check get a stub `run: "true"` plus `skip: true` under the dotfiles name. A YAML comment above the stubs says why the stub needs `run`.
  - `pre-commit`: `rubocop` (repository `rubocop-app`).
  - `pre-push`: `rubocop` (repository `rubocop-app`), `brakeman` (`brakeman-app`), `bundle-audit` (`bundler_audit`), `minitest` (the repository `tests` runs the full suite, a superset).
  - `erb_lint` is not a duplicate: it is a different linter from the Node herb linter and `herb analyze`. It stays on (intent decision).
- The two repository files merge as follows, with the herb duplicate removed in favour of the `.lefthook.yml` yarn version (intent constraint):
  - `pre-commit`: `rubocop-app` (tag `rubocop`, glob `*.rb`, `bundle exec rubocop --force-exclusion {staged_files}`), `herb-lint` (glob `*.erb`, `yarn run herb-lint {staged_files}`, with its `fail_text`), `i18n-normalized` (unchanged).
  - `pre-push`: `rubocop-app` (`bundle exec rubocop`), `brakeman-app` (`bundle exec brakeman --no-pager -q`), `bundler_audit`, `tests`, `herb-lint-full`, `herb-analyze`, `i18n-normalized` (all unchanged).
  - The `lefthook.yml` `herb` commands (`npx @herb-tools/linter`) are dropped.
- `yamllint` skips locale files through a lefthook `exclude: ["config/locales/**"]` on a `yamllint` stub (`run: "true"`) in both `pre-commit` and `pre-push`. The dotfiles `run`, `glob` and `tags` win; the `exclude` survives. Rejected: a repository `.yamllint` file with `ignore:`. It would replace the user's global yamllint config for this repository, and it adds a second config file to keep in step. Without the dotfiles the stub runs `true`, so contributors get no new check.
- Dotfiles checks that are not duplicates stay on, as the intent requires: `ruby-syntax`, `erb_lint`, `yamllint`, `stylelint`, `eslint`, `browserslist`, `shellcheck`, `no-hardwrap`, the `no-*` guards, `review-report-fresh`, `rspec` (a no-op here: no `spec/`), `post-merge`, `post-rewrite`, `migrations`.
- `no_auto_install`, `parallel: true` and the `post-merge`/`post-rewrite` file lists come from the dotfiles file. The repository file does not repeat them: for a contributor without the dotfiles, lefthook defaults apply, as today. `parallel: true` for the repository pre-push checks is accepted (intent decision).
- The five approved packages go into `package.json` `devDependencies` through `yarn add --dev`, with yarn's caret ranges (`^17.16.0`, `^40.0.0`, `^10.13.0`, `^10.0.1`, `^17.13.0`), the style `@herb-tools/linter` already uses. `yarn.lock` changes with them. Yarn, not npm (dependencies skill).
- `stylelint.config.mjs` extends `stylelint-config-standard`. It sets `selector-class-pattern` and `selector-id-pattern` to kebab-case or the one Rails name each (`field_with_errors`, `error_explanation`), with a comment that Rails generates these names. Rejected: renaming them. `field_with_errors` comes from Rails `field_error_proc`, so a rename needs a Rails override, and `error_explanation` spans 6 views and 3 tests, outside the intent's "existing CSS and JS". Rejected: turning the two rules off, which drops the naming check for every other selector. The other 5 errors are fixed in the CSS with `stylelint --fix`.
- `eslint.config.mjs` is a flat config: `@eslint/js` `recommended`, `globals.browser`, `sourceType: "module"`, for `**/*.js`. The `.mjs` extension keeps it ESM without adding `"type": "module"` to `package.json`. It declares no extra globals. The 3 errors are fixed in the code:
  - `application.js`: `import "@hotwired/turbo-rails"` becomes `import { Turbo } from "@hotwired/turbo-rails"`. The module still runs its side effects, so Turbo starts as before.
  - `channels/index.js`: deleted. Nothing loads it, and its `require.context` cannot run under importmap.
  - `clipboard_controller.js`: `catch (_error)` becomes `catch`, an optional catch binding.
- `application.html.erb`: the closing `>` of the `<html` tag moves to the end of the `data-theme` line, the `erb_lint -a` output.
- Proof is by scripted checks, the existing test suite and a browser check, not a new Minitest file. The change has no Ruby code. A test that parses `lefthook.yml` only restates the file. CI has no dotfiles, so a committed test of the merged config would have to skip there, and the playbook forbids skipped tests. The pull mechanics themselves are already covered in the dotfiles by `test/lefthook_pull_hooks_test.rb`. No existing test drives the custom `#confirm-dialog` flow that `application.js` sets up: `test/system/chattels_test.rb` uses Capybara's native `accept_confirm`. System tests do not run on this machine today (Selenium: "This version of ChromeDriver only supports Chrome version 155"), and CI runs no tests. So the JS edits are proved in a browser against the running app (Proof). A new system test for the dialog is rejected here: it could not run locally or in CI, and the dialog is outside this change. Each check runs red before its change and green after it.

## Integration points

- Global hook shim `~/.config/git/hooks/{pre-commit,pre-push,post-merge,post-rewrite,commit-msg}`: it still finds a repository config and leaves `LEFTHOOK_CONFIG` unset. Not changed.
- `~/Developer/dotfiles/lefthook.yml`: read through `extends:`. Not changed.
- The nested `lefthook run migrations --files-from-stdin` in the dotfiles `post-merge`/`post-rewrite` reads the repository `lefthook.yml` again, so the `migrations` section comes in through the same `extends:`.
- `bi`, `rails db:migrate`, `yarn install`: called by the dotfiles `migrations` steps. The `yarn.lock` change in this branch makes the next pull of `main` run `yarn install`, as intended.
- CI (`.github/workflows/ci.yml`) does not use lefthook. Its `lint_erb` job runs `yarn install --frozen-lockfile`, so `yarn.lock` must match `package.json`. CI is not changed.
- Dependabot already watches the `npm` ecosystem at `/`, so it picks up the new packages. Not changed.

## Files that change

- `app/views/layouts/application.html.erb` — the `>` of the `<html` tag moves up one line.
- `package.json`, `yarn.lock` — five devDependencies.
- `stylelint.config.mjs` — new.
- `app/assets/stylesheets/application.css`, `app/assets/stylesheets/local/layout/application_page.css`, `app/assets/stylesheets/local/modules/search_dialog.css` — the `stylelint --fix` corrections, nothing else.
- `eslint.config.mjs` — new.
- `app/javascript/application.js` — named `Turbo` import.
- `app/javascript/channels/index.js` — deleted.
- `app/javascript/controllers/clipboard_controller.js` — optional catch binding.
- `lefthook.yml` — rewritten: an exact `extends:` path, merged repository checks under non-colliding names, skip stubs for the dotfiles duplicates, `yamllint` exclude stubs, short comments that explain the path and the stubs.
- `.lefthook.yml` — deleted; its checks move into `lefthook.yml`.
- `lefthook-local.yml` — deleted (comment-only).

Nothing else. `AGENTS.md` and `CLAUDE.md` stay true: lefthook still runs the listed checks on push.

## Order of work

Work in the worktree. Run `yarn install` there first (AGENTS.md gotcha). Put the worktree's `bin/` first on `PATH` for every `bin/rails` and push (AGENTS.md gotcha). The helper scripts under Test setup live in the session scratchpad and are never committed. The four commits below each hold one logical change. Until commit 4 lands, only the old repository `lefthook.yml` runs on commit.

1. Write the `pull-check` and `commit-check` scripts in the scratchpad (Test setup).
2. Run `pull-check merge schema` against the current branch head. Watch it fail: the marker file has no `MIGRATE`. Run `bin/lefthook dump`. Watch it fail: no `post-merge`, `post-rewrite` or `migrations`.
3. Run `erb_lint app/views/layouts/application.html.erb`. Watch it report the offence on line 7. Fix the line as in Design decisions. Run `erb_lint` again (no errors) and `yarn run herb-lint app/views/layouts/application.html.erb` (no errors). Commit 1: `Close the html tag on its last attribute line for erb_lint`.
4. Run `yarn stylelint "app/assets/stylesheets/**/*.css"`. Watch it fail: yarn reports the command is not found. Run `yarn add --dev stylelint@^17.16.0 stylelint-config-standard@^40.0.0`. Write `stylelint.config.mjs`. Run `yarn stylelint "app/assets/stylesheets/**/*.css"` and confirm the 14 errors of Context. Run it with `--fix`. Confirm that the diff in the three CSS files is only the 3 corrections of Context, and that the run exits 0. Commit 2: `Lint CSS with stylelint-config-standard`.
5. Run `yarn eslint app/javascript`. Watch it fail: command not found. Run `yarn add --dev eslint@^10.13.0 @eslint/js@^10.0.1 globals@^17.13.0`. Write `eslint.config.mjs`. Run `yarn eslint app/javascript` and confirm the 3 errors of Context. Fix the two files and delete `channels/index.js` as in Design decisions. Run `yarn eslint app/javascript` (exit 0). Do the browser check of Proof. Commit 3: `Lint JavaScript with eslint recommended`.
6. Run `yamllint config/locales/en.yml`. Watch it fail on `indentation` (this is why the exclude exists).
7. Rewrite `lefthook.yml` as in Design decisions. Delete `.lefthook.yml` and `lefthook-local.yml`. Run `bin/lefthook dump`. Confirm the four hooks, every repository command, `skip: true` on each dotfiles duplicate, and the `exclude` on both `yamllint` jobs.
8. Run the no-dotfiles check: a scratch clone of the branch head with the new `lefthook.yml` and the two deletions copied in, and its `extends:` path pointed at a file that does not exist, with the worktree's `node_modules` linked in. `lefthook run pre-commit --all-files` and `lefthook run pre-push --all-files` there must both exit 0, and their output must list only the repository jobs and the `run: "true"` stubs. This proves the stubs are valid for contributors without the dotfiles.
9. Commit 4: `Keep one lefthook config that extends the dotfiles defaults`. This commit is the first to run the dotfiles pre-commit checks; it must pass them without `--no-verify`.
10. Run the pull checks on the committed head: `pull-check merge schema`, `pull-check rebase schema`, `pull-check merge other`.
11. Run the commit checks on the committed head: `commit-check locale` and `commit-check layout`.
12. Run `yamllint lefthook.yml`. Then run `bin/lefthook run pre-commit --all-files` and `bin/lefthook run pre-push --all-files` once each. Confirm from the output that every repository job runs once, every skipped duplicate shows as skipped, and `stylelint`, `eslint` and `yamllint` pass. `erb_lint` with `--all-files` is expected to fail on `app/views/layouts/admin.html.erb` alone (see Risks); confirm that it reports no other file, record it, and do not fix it. The pass of `erb_lint` on the changed layout is proved by `commit-check layout`.
13. Run `bundle exec rubocop`, `yarn run herb-lint app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check` and `bin/rails test`. All green.
14. Push from the worktree with its `bin/` first on `PATH`. The pre-push hook runs the merged config.

## Risks

- `erb_lint` reports the same `SpaceInHtmlTag` offence in `app/views/layouts/admin.html.erb:7`. The intent names only `application.html.erb`, so this plan leaves it. `erb_lint` runs on staged and pushed files only, so nothing fails until someone changes `admin.html.erb`; that commit then fails until the same one-line fix is made. This is a `Decision needed:` line in the report.
- The `selector-class-pattern` and `selector-id-pattern` exceptions hold one name each. A new Rails-generated snake_case name in the CSS fails the check and needs its own entry, or a rename.
- `application.js` now names `Turbo` through the import. The module object is the same one `turbo-rails` puts on `window.Turbo`, so `Turbo.config.drive.confirmationMethod` sets the same field. The browser check proves the custom dialog still opens.
- System tests fail to start on this machine (ChromeDriver and the cached Chrome for Testing build differ). That is a machine tooling problem, so playbook rule 8 keeps it out of this change. `test/system/chattels_test.rb` "should destroy Chattel from show page" also uses native `accept_confirm` against a page that shows the custom dialog, so it may fail once Chrome works again. Both are orthogonal; the report names them.
- If the dotfiles later give a duplicate command its own `skip:` key, or give `yamllint` its own `exclude:`, the extended value wins. A duplicate then runs again, or locale files get linted again. The stub comment names this.
- `parallel: true` from the dotfiles makes the repository `pre-push` commands run in parallel. Today they run one after another. The output interleaves, and the test suite competes with rubocop and brakeman for CPU. No check changes its result.
- `review-report-fresh` now runs on push. Once a pull request is open, a push needs a fresh `review.md`. This is the dotfiles workflow in every other repository.
- The dotfiles `post-rewrite` also fires on `git commit --amend`, with a possibly stale `ORIG_HEAD`. It can run `rails db:migrate` when nothing changed. `db:migrate` is idempotent. The dotfiles own this behaviour; out of scope.
- `erb_lint`, `yamllint`, `shellcheck` and `markdownlint` come from the machine, not from the repository. That is the dotfiles' choice for every repository; out of scope.
- On a machine where Etienne's user is not `etienne.vandelden`, the dotfiles defaults do not load, silently, as today. The comment above `extends:` names the path to change.
- Rejected: the `/Users/*` glob (see Design decisions); `remotes:` (network, `lefthook install`, out of scope); keeping `lefthook-local.yml` for overrides (the intent requires one file); a `.yamllint` file (see Design decisions).

## Out of scope

- Any change to `~/Developer/dotfiles` or the global shim.
- The `erb_lint` offence in `app/views/layouts/admin.html.erb`.
- `app/javascript/channels/consumer.js`, also never loaded. Removing it is an orthogonal cleanup for a separate branch.
- Running `stylelint` or `eslint` in CI, or any other CI workflow change.
- Removing the stale `.git/info/lefthook-remotes/dotfiles` clone.

## Proof

- The repository holds one lefthook config file, and `lefthook-local.yml` is gone → check: `git ls-files | grep -E '(^|/)\.?lefthook(-local)?\.yml$'` prints only `lefthook.yml`.
- `lefthook dump` shows `pre-commit`, `pre-push`, `post-merge` and `post-rewrite` → check: `bin/lefthook dump | grep -E '^(pre-commit|pre-push|post-merge|post-rewrite|migrations):'` prints all five keys.
- Pulling a commit that changes `db/schema.rb` runs the migrations step → check: `pull-check merge schema` writes `MIGRATE` to the marker file.
- Pulling with a rebase runs the migrations step too → check: `pull-check rebase schema` writes `MIGRATE` to the marker file.
- Pulling a commit that leaves `db/schema.rb` alone does not run the migrations → check: `pull-check merge other` leaves the marker file without `MIGRATE`.
- Every check from the old files still runs on commit or push, and none runs twice → check: in the `bin/lefthook dump` output, `pre-commit` holds `rubocop-app`, `herb-lint`, `i18n-normalized` without `skip`, and `rubocop` with `skip: true`; `pre-push` holds `rubocop-app`, `brakeman-app`, `bundler_audit`, `tests`, `herb-lint-full`, `herb-analyze`, `i18n-normalized` without `skip`, and `rubocop`, `brakeman`, `bundle-audit`, `minitest` with `skip: true`. No `herb` command remains. Then the run output of Order of work step 12 lists each repository job once and each skipped duplicate as skipped.
- `yarn stylelint` and `yarn eslint` run in the repository and pass on the existing CSS and JS → check: `yarn stylelint "app/assets/stylesheets/**/*.css"` and `yarn eslint app/javascript` exit 0; `bin/lefthook run pre-commit --all-files --command stylelint --command eslint` passes.
- Committing a locale file normalized by `i18n-tasks normalize` passes both `yamllint` and `i18n-normalized` → check: `commit-check locale` exits 0, and its output shows `i18n-normalized` passed and `yamllint` skipped for no matching files.
- Committing `app/views/layouts/application.html.erb` passes `erb_lint` → check: `commit-check layout` exits 0, and its output shows `erb_lint` and `herb-lint` passed.
- Contributors without the dotfiles are not broken (intent constraint) → check: Order of work step 8 exits without a lefthook config error.
- The JavaScript edits keep the pages working (regression) → check: run the worktree app (`DISABLE_SSL=1`, port 3001, `127.0.0.1`, a copy of the development database), sign in, open a chattel and click Destroy: the custom `#confirm-dialog` opens with the Delete label, and Cancel keeps the chattel. Then press a `clipboard` copy button: no error appears in the browser console. The browser console shows no error on page load.

Per changed file, the unit tests expected: none. `lefthook.yml`, `package.json` and the two linter configs are configuration, the CSS edits are notation-only, and the JS edits are proved by the browser check above.

Test setup: two scratchpad shell scripts, never committed. Both clone the worktree's committed head into a fresh scratchpad directory, link the worktree's `node_modules` into the clone, and print the hook output and exit status.

- `pull-check <merge|rebase> <schema|other>` clones the head as `upstream`, and clones `upstream` as `downstream`. In `upstream` it commits (with `--no-verify`) either a comment line appended to `db/schema.rb` or a change to `README.md`. In `downstream` it puts a fake-bin directory first on `PATH` with `rails` (appends `MIGRATE` to a marker file), `bi` and `yarn` (append their names), sets `LEFTHOOK_QUIET=` empty, and runs `git pull --no-rebase` or, for `rebase`, first makes a local commit on another file (with `--no-verify`) and runs `git pull --rebase`. The global hook shim runs as on any pull. The script prints the marker file. No real database or gem install is touched.
- `commit-check <locale|layout>` makes one edit in the clone and runs a real `git commit`, so the global shim runs the merged `pre-commit`. For `locale` it changes the English value of one existing key in `config/locales/en.yml`, runs `bundle exec i18n-tasks normalize`, and stages `config/locales/en.yml`. For `layout` it adds an ERB comment line (`<%# commit-check %>`) inside `<head>` of `app/views/layouts/application.html.erb` and stages it.

---
Domain skills applied: dependencies (yarn, caret ranges, approval recorded in the intent); rails-ui (view, CSS and Stimulus/Turbo JavaScript edits).

## Critique

### Round 1 (codex -p terra)

- The `/Users/*/Developer/dotfiles/lefthook.yml` glob can load another local user's config, so it permits unintended hook code → fixed (one exact path; the glob and a second `/Users/eirvandelden` path are rejected in Design decisions, because `/Users/Shared` and `/Users/eirvandelden` are world-writable here)
- Step 12 expects `erb_lint` to pass on all files while Risks says `admin.html.erb` fails it → fixed (step 12 expects the all-files `erb_lint` failure on `admin.html.erb` alone; `commit-check layout` proves the changed file)
- The no-dotfiles check runs all jobs in a scratch copy without `node_modules`, so yarn jobs can fail for unrelated reasons → fixed (step 8 links `node_modules` and requires both runs to exit 0)
- The cited system test uses native `accept_confirm`, so it does not exercise the custom `#confirm-dialog` flow → fixed (the claim is gone; a browser check against the running app proves the JS edits, and Risks records that system tests cannot start on this machine)
  - A new system test for the dialog was not added: it cannot run locally (ChromeDriver mismatch) or in CI (no test job), and the dialog is outside this change.
- The stylelint baseline miscounts the selector errors → fixed (Context states 5 auto-fixed errors at 3 places and 9 selector errors: 6 class, 3 id)
