# Plan: One lefthook config that builds on the dotfiles defaults

From `intent.md` (2026-10-16). Status: accepted.

## Context

The global hook shim in `~/.config/git/hooks/*` sets `LEFTHOOK_CONFIG` to `~/Developer/dotfiles/lefthook.yml` only when the repository has no `lefthook.yml`, `.lefthook.yml` or `.config/lefthook.yml`. This repository has `lefthook.yml` and `.lefthook.yml`, so the dotfiles `post-merge`, `post-rewrite` and `migrations` sections never load here.

Facts checked on 2026-10-16. Inside this repository both `bin/lefthook` and the `lefthook` on `PATH` run 2.1.12, the `Gemfile.lock` version. A scratch repository without a Gemfile ran 2.2.2 and behaved the same:

- Today `lefthook dump` in this repository shows only `lefthook.yml`. Lefthook ignores `.lefthook.yml` when `lefthook.yml` exists. So `herb-lint`, `herb-analyze` and `i18n-normalized` do not run today, and the `remotes:` entry in `.lefthook.yml` has no effect.
- `extends:` does not expand `~` or `$HOME`. An absolute path works, and so does a glob such as `/Users/*/Developer/dotfiles/lefthook.yml`.
- An `extends:` path or glob that matches no file is ignored silently. The config still loads.
- The extended file wins over the main file, field by field. A repository command with the same name as a dotfiles command gets the dotfiles `run`. A field that only the repository sets, such as `skip: true`, survives the merge.
- A command with `skip: true` and no `run` makes `lefthook run` exit 1 with "either `run`, `script`, or `group` must be provided" when the extended file is absent. A stub with `run: "true"` and `skip: true` is valid in both cases.

## Design decisions

- Load the dotfiles defaults through `extends: [/Users/*/Developer/dotfiles/lefthook.yml]`. The glob works for any macOS user name (`etienne.vandelden`, `eirvandelden`). For a contributor without the dotfiles it matches nothing, so they get only the repository checks. `remotes:` is rejected: it needs a network fetch and `lefthook install`, and the intent puts the `remotes:` mechanism out of scope.
- The single file is `lefthook.yml`. It is the file lefthook already reads, and the `bin/lefthook` binstub and the docs already point at it. `.lefthook.yml` and `lefthook-local.yml` are deleted.
- Repository commands never reuse a dotfiles command name, because the dotfiles `run` would replace theirs. The repository `rubocop` becomes `rubocop-app` in `pre-commit` and `pre-push`, and `brakeman` becomes `brakeman-app` in `pre-push`. `bundler_audit` and `tests` keep their names; the dotfiles names differ (`bundle-audit`, `minitest`).
- Dotfiles commands that duplicate a repository check get a stub `run: "true"` plus `skip: true` under the dotfiles name. A YAML comment above the stubs says why the stub needs `run`.
  - `pre-commit`: `rubocop` (repository `rubocop-app`).
  - `pre-push`: `rubocop` (repository `rubocop-app`), `brakeman` (`brakeman-app`), `bundle-audit` (`bundler_audit`), `minitest` (the repository `tests` runs the full suite, a superset).
  - `erb_lint` is not a duplicate: it is a different linter from the Node herb linter and `herb analyze`. It stays on.
- The two repository files merge as follows, with the herb duplicate removed in favour of the `.lefthook.yml` yarn version (intent constraint):
  - `pre-commit`: `rubocop-app` (tag `rubocop`, glob `*.rb`, `bundle exec rubocop --force-exclusion {staged_files}`), `herb-lint` (tag `herb`, glob `*.erb`, `yarn run herb-lint {staged_files}`, with its `fail_text`), `i18n-normalized` (unchanged).
  - `pre-push`: `rubocop-app` (`bundle exec rubocop`), `brakeman-app` (`bundle exec brakeman --no-pager -q`), `bundler_audit`, `tests`, `herb-lint-full`, `herb-analyze`, `i18n-normalized` (all unchanged).
  - The `lefthook.yml` `herb` commands (`npx @herb-tools/linter`) are dropped.
- Dotfiles checks that are not duplicates stay on, as the intent requires: `ruby-syntax`, `erb_lint`, `yamllint`, `stylelint`, `eslint`, `shellcheck`, `no-hardwrap`, the `no-*` guards, `review-report-fresh`, `rspec` (a no-op here: no `spec/`), `post-merge`, `post-rewrite`, `migrations`. Some of them fail on this repository's files; see Risks and the decisions listed there.
- `no_auto_install`, `parallel: true` and the `post-merge`/`post-rewrite` file lists come from the dotfiles file. The repository file does not repeat them: for a contributor without the dotfiles, lefthook defaults apply, as today.
- Proof is by scripted checks, not a Minitest file. The change has no Ruby code. A test that parses `lefthook.yml` only restates the file. CI has no dotfiles, so a committed test of the merged config would have to skip there, and the playbook forbids skipped tests. The pull mechanics themselves are already covered in the dotfiles by `test/lefthook_pull_hooks_test.rb`. The checks run red before the change and green after it (Order of work step 2).

## Integration points

- Global hook shim `~/.config/git/hooks/{pre-commit,pre-push,post-merge,post-rewrite,commit-msg}`: it still finds a repository config and leaves `LEFTHOOK_CONFIG` unset. Not changed.
- `~/Developer/dotfiles/lefthook.yml`: read through `extends:`. Not changed.
- The nested `lefthook run migrations --files-from-stdin` in the dotfiles `post-merge`/`post-rewrite` reads the repository `lefthook.yml` again, so the `migrations` section comes in through the same `extends:`.
- `bi`, `rails db:migrate`, `yarn install`: called by the dotfiles `migrations` steps.
- CI (`.github/workflows/ci.yml`) does not use lefthook. Not changed.

## Files that change

- `lefthook.yml` — rewritten: `extends:` glob, merged repository checks under non-colliding names, skip stubs for the dotfiles duplicates, short comments that explain the glob and the stubs.
- `.lefthook.yml` — deleted; its checks move into `lefthook.yml`.
- `lefthook-local.yml` — deleted (comment-only).

Nothing else. `AGENTS.md` and `CLAUDE.md` stay true: lefthook still runs the listed checks on push.

## Order of work

All checks use the helper script described under Test setup, kept in the session scratchpad, never committed.

1. Write the `pull-check` script in the scratchpad (Test setup).
2. Run the pull check (merge pull that changes `db/schema.rb`) against the current branch head. Watch it fail: the migrations marker does not appear.
3. Run the `lefthook dump` check against the current files. Watch it fail: no `post-merge`, `post-rewrite` or `migrations`.
4. Rewrite `lefthook.yml` as in Design decisions. Delete `.lefthook.yml` and `lefthook-local.yml`.
5. Run `bin/lefthook dump`. Confirm the four hooks, every repository command, and `skip: true` on each dotfiles duplicate.
6. Run the no-dotfiles check: a copy of `lefthook.yml` with the glob pointed at a path that does not exist. `lefthook run pre-commit --all-files` and `lefthook run pre-push --all-files` must not report a config error. This proves the stubs are valid for contributors without the dotfiles.
7. Commit (`build: keep one lefthook config that extends the dotfiles defaults`).
8. Run the pull checks again on the committed head: merge pull with schema change, rebase pull with schema change, merge pull without schema change.
9. Run `yamllint lefthook.yml`, then `bin/lefthook run pre-commit --all-files` and `bin/lefthook run pre-push --all-files` once each. Confirm from the output that every repository job runs once and every skipped duplicate shows as skipped. Record failures of dotfiles checks on existing repository files (see Risks); fix only what this change caused.
10. Push from the worktree with its `bin/` first on `PATH` (AGENTS.md gotcha), after `yarn install` in the worktree.

## Risks

- Dotfiles checks that are not duplicates fail on this repository's files. Verified on 2026-10-16:
  - `stylelint` and `eslint` run as `yarn stylelint`/`yarn eslint`. `package.json` has neither package, so yarn exits 1 ("Command not found"). Any commit with CSS, or push with JS, fails.
  - `yamllint` reports `indentation` errors in `config/locales/en.yml`. `i18n-tasks normalize` produces that indentation, and the repository's `i18n-normalized` check requires it. A commit that touches a locale file cannot pass both.
  - `erb_lint` reports offences in `app/views/layouts/application.html.erb`. A commit with that view fails.
  - The plan keeps `stylelint`, `eslint`, `yamllint` and `erb_lint` on, because the intent says the effective config is the dotfiles defaults plus the repository checks, with only duplicates removed. Each is a `Decision needed:` line in the report.
- If the dotfiles later give a duplicate command its own `skip:` key, the extended value wins and the duplicate runs again. The stub comment names this.
- `parallel: true` from the dotfiles makes the repository `pre-push` commands run in parallel. Today they run one after another. The output interleaves, and the test suite competes with rubocop and brakeman for CPU. No check changes its result.
- `review-report-fresh` now runs on push. Once a pull request is open, a push needs a fresh `review.md`. This is the dotfiles workflow in every other repository.
- The dotfiles `post-rewrite` also fires on `git commit --amend`, with a possibly stale `ORIG_HEAD`. It can run `rails db:migrate` when nothing changed. `db:migrate` is idempotent. The dotfiles own this behaviour; out of scope.
- Rejected: a hard-coded `/Users/etienne.vandelden/...` path (breaks on a machine with another user name); `remotes:` (network, `lefthook install`, out of scope); keeping `lefthook-local.yml` for overrides (the intent requires one file).

## Out of scope

- Any change to `~/Developer/dotfiles` or the global shim.
- Skipping, configuring or fixing the findings of `stylelint`, `eslint`, `yamllint` or `erb_lint` in this repository, or adding their packages or configs.
- CI workflow changes.
- Removing the stale `.git/info/lefthook-remotes/dotfiles` clone.

## Proof

- The repository holds one lefthook config file, and `lefthook-local.yml` is gone → check: `git ls-files | grep -E '(^|/)\.?lefthook(-local)?\.yml$'` prints only `lefthook.yml`.
- `lefthook dump` shows `pre-commit`, `pre-push`, `post-merge` and `post-rewrite` → check: `bin/lefthook dump | grep -E '^(pre-commit|pre-push|post-merge|post-rewrite|migrations):'` prints all five keys.
- Pulling a commit that changes `db/schema.rb` runs the migrations step → check: `pull-check merge schema` writes `MIGRATE` to the marker file.
- Pulling with a rebase runs the migrations step too → check: `pull-check rebase schema` writes `MIGRATE` to the marker file.
- Pulling a commit that leaves `db/schema.rb` alone does not run the migrations → check: `pull-check merge other` leaves the marker file without `MIGRATE`.
- Every check from the old files still runs on commit or push, and none runs twice → check: in the `lefthook dump` output, `pre-commit` holds `rubocop-app`, `herb-lint`, `i18n-normalized` without `skip`, and `rubocop` with `skip: true`; `pre-push` holds `rubocop-app`, `brakeman-app`, `bundler_audit`, `tests`, `herb-lint-full`, `herb-analyze`, `i18n-normalized` without `skip`, and `rubocop`, `brakeman`, `bundle-audit`, `minitest` with `skip: true`. No `herb` command remains. Then the run output of Order of work step 9 lists each repository job once and each skipped duplicate as skipped.
- Contributors without the dotfiles are not broken (intent constraint) → check: Order of work step 6 exits without a lefthook config error.

Per changed file, the unit tests expected: none. `lefthook.yml` is configuration; the checks above cover it.

Test setup: `pull-check <merge|rebase> <schema|other>` is a scratchpad shell script. It clones the worktree's committed head into a fresh scratchpad directory as `upstream`, and clones `upstream` as `downstream`. In `upstream` it commits (with `--no-verify`) either a comment line appended to `db/schema.rb` or a change to `README.md`. In `downstream` it puts a fake-bin directory first on `PATH` with `rails` (appends `MIGRATE` to a marker file), `bi` and `yarn` (append their names), sets `LEFTHOOK_QUIET=` empty, and runs `git pull --no-rebase` or, for `rebase`, first makes a local commit on another file (with `--no-verify`) and runs `git pull --rebase`. The global hook shim runs as on any pull. The script prints the marker file. No real database or gem install is touched.

---
Domain skills applied: None (git hook configuration; no Rails, UI or dependency change).

## Critique

### Round 1 (codex -p terra)

- `erb_lint` is a different linter from the herb checks, so skipping it as a duplicate violates the intent → fixed (`erb_lint` stays on; its failing view moved to Risks and to a decision line)
- `stylelint`, `eslint` and `yamllint` fail here, and the plan leaves that unresolved although the intent has no open questions → dismissed: auto mode must not change agreed behaviour; the plan follows the intent literally and reports each check as a `Decision needed:` line for the coordinator
- The proof is not reproducible: `pull-check` is an uncommitted script used before it exists, and `lefthook dump` proves declared jobs, not executed jobs → fixed (step 1 writes the script first; step 9 runs both hooks and checks each job runs once; a committed test is not added because CI has no dotfiles, so it would have to skip, and the dotfiles already test the pull mechanics)
- The plan claims the `PATH` `lefthook` is 2.2.2, but inside the repository both binaries are 2.1.12 → fixed (Context states the observed versions; the second dump run is removed)
