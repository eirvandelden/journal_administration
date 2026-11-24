# Review: fix-lefthook-git-dir

## Round 1 — 2026-11-24T19:14Z — 8890577b

- [x] Important: The pre-commit `i18n-normalized` job never runs. Its glob `config/locales/**/*.yml` needs at least one directory under `**/` with lefthook's default glob matcher, and every locale file is top-level (`en.yml`, `nl.yml`, `it.yml`). Verified: `lefthook run pre-commit --command i18n-normalized --file config/locales/en.yml` prints "(skip) no matching staged files", while the same `--file` run of `herb-lint` on a view executes. A commit of an unnormalized locale file passes; only the pre-push job catches it, although `AGENTS.md` now promises the i18n check on commit. Use `config/locales/*.yml` (or list both patterns). — `lefthook.yml:19` → fixed (Run the i18n check on top-level locale files at commit)
- [x] Nit: The new hooks line says lefthook runs "on commit and push". The shared config also installs `commit-msg`, `post-checkout` (`worktree-init-on-create`) and `post-merge`/`post-rewrite` `migrations`, which run `bi`, `npm install` and `rails db:migrate` after a pull or rebase that touches `Gemfile*`, `package*.json` or `db/migrate`. An agent that reads `AGENTS.md` cannot tell that a rebase can migrate its development database. The plan's Risks section does not name it either. — `AGENTS.md:29` → fixed (Document the shared post-merge and post-rewrite hooks in AGENTS.md)
- [x] Nit: The shared `rubocop` jobs call `rubocop` from `PATH` (1.92.3, rubocop-yard 1.4.0), not the locked versions (1.92.1, rubocop-yard 1.3.0) that the removed `bundle exec rubocop` job used. Hook results can differ from CI. The fix belongs in the dotfiles shared config, which this change keeps out of scope; record it as a follow-up there. — `lefthook.yml:1` → dismissed: the shared rubocop job lives in the dotfiles config, which this change keeps out of scope; follow-up for the dotfiles repository
- [x] Nit: The example in `lefthook-local.yml` skips a job named `herb`. That job no longer exists after this change (`herb-lint`, `herb-lint-full`, `herb-analyze`), so a copy of the example skips nothing. — `lefthook-local.yml:5` → fixed (Name the herb-lint job in the local skip example)
- [x] Nit: The Risks section names only the msgpack and puma advisories. `bundle-audit` now also reports net-ssh 7.3.6 (needs `~> 7.3.10` or `>= 8.1.2`). The rule-25 follow-up branch must include it. — `docs/changes/fix-lefthook-git-dir/plan.md:147` → fixed (Name the net-ssh advisory in the plan risks)

Compliance (config only; the plan names no code tests):

- Criterion 1, push from a worktree runs shared rubocop, brakeman, bundle-audit, minitest with real results: verified with `GIT_DIR=<worktree git dir> lefthook run pre-push --all-files` for those jobs. rubocop: 403 files, no offences. brakeman: no warnings. bundle-audit: fails on real advisories (msgpack, net-ssh, puma). minitest (`--file app/models/account.rb`): 45 runs, 0 failures. No exit status 7, no git-gem error.
- Criterion 2, a staged Ruby file runs rubocop on commit: the effective config (`lefthook dump`) has the shared pre-commit `rubocop` job with `unset GIT_DIR`; the same command passes in the worktree with `GIT_DIR` set. Not exercised with a staged file (review stages nothing).
- Criterion 3, an offence still blocks the commit: the job propagates rubocop's exit status (no `|| true`). Not exercised with a staged file.
- Criterion 4, main checkout: provable only after merge, as the plan states.
- Invariants: `lefthook dump` shows the shared config plus the four local jobs, with `skip: true` on `erb_lint`. `i18n-normalized`, `herb-analyze` and `herb-lint-full` pass on pre-push with `GIT_DIR` set.
- No existing test weakened, skipped or deleted. Design pass: no Ruby in the diff, no glossary terms touched.

## Round 2 — 2026-11-24T19:17Z — 14e21ccf

- [x] Important: The shared pre-commit `yamllint` job, which this change brings in through `remotes:`, rejects every locale file in the form `i18n-tasks normalize` writes. Normalized files put sequence items at the key's indentation (`order:` then `- year` at the same column); yamllint's `indentation` rule wants them indented. Verified: `lefthook run pre-commit --command yamllint --file config/locales/en.yml` with the worktree `GIT_DIR` set exits 1 with "wrong indentation: expected 6 but found 4" (5 errors each in `en.yml`, `it.yml`, `nl.yml`), while `i18n-normalized` passes on the same file. Any commit that touches a locale file is refused, and normalizing cannot fix it, so the only way through is a skipped hook. That breaks the outcome "a push from a worktree no longer needs any hook skipped". No other tracked YAML file has a yamllint error. Options: a local `exclude` (or `skip`) for `yamllint` on `config/locales/*.yml` in `lefthook.yml`, like the `erb_lint` override; or a repository `.yamllint` that accepts unindented sequences. The second is a linter config, so Etienne decides. — `lefthook.yml:12` → fixed (Skip browserslist and exclude locale files from yamllint in the hooks)
- [x] Nit: The shared `browserslist` job (pre-commit and pre-push, glob `.browserslistrc`) runs `npx --no browserslist`, and browserslist is not installed here: it exits 1 with "npx canceled due to missing packages". A commit or push that touches `.browserslistrc` is refused. The plan solves the same case for `erb_lint` with `skip: true`. The file is a webpacker leftover (`iOS >= 5`); skip the job or delete the file. — `lefthook.yml:12` → fixed (Skip browserslist and exclude locale files from yamllint in the hooks)
- [x] Nit: `plan.md` no longer matches the code. `### Signatures` still shows the pre-commit glob `config/locales/**/*.yml` that round 1 fixed to `config/locales/*.yml`. The first `## Proof` bullet still expects bundle-audit to fail on "the msgpack and puma advisories", without net-ssh. — `docs/changes/fix-lefthook-git-dir/plan.md:66` → fixed (Sync the plan with the hook config and the advisories)

Round 1 fixes verified:

- `i18n-normalized` now runs at commit: `lefthook run pre-commit --command i18n-normalized --file config/locales/en.yml` with `GIT_DIR` set prints "Locale files are normalized." and exits 0. All locale files are top-level, so `config/locales/*.yml` covers them.
- `AGENTS.md` names the post-checkout, post-merge and post-rewrite hooks; `lefthook-local.yml` names `herb-lint`; the plan Risks name net-ssh.

Other shared jobs checked against this repository: `eslint` and `stylelint` pass on every tracked `.js` and `.css` file (configs and packages present). `yamllint` passes on `lefthook.yml` and `lefthook-local.yml`. No shell files are tracked. `lefthook dump` still shows `skip: true` on both `erb_lint` jobs. Uncommitted changes: none besides this file. Design pass: no Ruby in the diff.

## Round 3 — 2026-11-24T20:27Z — c198cb56

- [x] Nit: The header comment says the file holds "Jobs the shared dotfiles config does not have" and that "the shared one runs" where both define a job. Three entries now adjust shared jobs (`erb_lint`, `browserslist`, `yamllint`), and lefthook merges their keys into the shared job: `lefthook dump` shows the shared `run` plus the local `skip: true` or `exclude`. A reader of the comment expects these overrides to do nothing, or to replace the shared job. Say that a local entry for a shared job adds or changes keys, and that the shared `run` stays. The same comment sits in `plan.md` under `### Signatures`. — `lefthook.yml:6` → fixed (Say that local entries merge into shared hook jobs)

Round 2 fixes verified (lefthook 2.2.2, worktree `GIT_DIR` set):

- `yamllint`: `lefthook dump` shows the shared job with `exclude: config/locales/*.yml` on pre-commit and pre-push. `lefthook run pre-commit --command yamllint --file config/locales/en.yml` prints "(skip) no files for inspection"; the same run on `lefthook.yml` still lints it and exits 0. All three locale files are top-level, so the pattern covers them. `i18n-normalized` still parses them, so a YAML syntax error is still caught at commit.
- `browserslist`: `lefthook dump` shows `skip: true` on both hooks; a run with `--file .browserslistrc` prints "(skip) by condition".
- `i18n-normalized` passes at commit with both `GIT_DIR` and `GIT_INDEX_FILE` set to the worktree's, as `git commit` sets them.
- `plan.md` `### Signatures` matches `lefthook.yml`, and the Proof names the net-ssh advisory.

Security: the `remotes:` stanza fetches the shared config over HTTPS from Etienne's own dotfiles repository, as the plan states. No secret, no new dependency. Design: no Ruby in the diff. Uncommitted changes: none besides this file.

## Round 4 — 2026-11-24T20:28Z — 51159a61

No findings. The repository has no `REVIEW.md` or `REVIEW.local.md`; the Bugs, Security, Compliance and Design passes follow the playbook, as in earlier rounds.

Round 3 fix verified (lefthook 2.2.2, worktree `GIT_DIR` and `GIT_INDEX_FILE` set, rv Ruby 4.0.7 first on `PATH`):

- The header comment in `lefthook.yml` now says that a local entry for a shared job merges its keys and that the shared `run` stays. `lefthook dump` confirms it: `erb_lint` and `browserslist` keep the shared `run` with `skip: true`, and `yamllint` keeps the shared `run` with `exclude: config/locales/*.yml`, on pre-commit and pre-push. The same comment in `plan.md` `### Signatures` matches the file.
- `lefthook run pre-commit --file config/locales/en.yml` runs the full hook: `yamllint` skips the file, `i18n-normalized` prints "Locale files are normalized.", and the hook exits 0.
- `lefthook run pre-commit --command yamllint --file lefthook.yml` still lints that file and exits 0. With `--command yamllint --file config/locales/en.yml` lefthook exits 1 with "no job matching yamllint", because the only selected job skips the file. This is the `--command` filter, not the real hook: the full run above exits 0.

Environment note: a non-interactive shell here resolves `ruby` and `bundle` to macOS system Ruby 2.6, and `bundle exec` then fails with `uninitialized constant Gem::Resolver::APISet::GemParser`. The cause is a `PATH` without rv's Ruby, not this change; with rv's Ruby first on `PATH` every Bundler job passes.

Compliance: the diff since round 3 is the comment in `lefthook.yml` and `plan.md` alone. It matches the intent's "the shared job wins where jobs overlap": overlapping keys come from the shared config, and only keys the shared job lacks are added. `.lefthook.yml` is deleted. Security: nothing new. Design: no Ruby in the diff. Uncommitted changes: none besides this file.
