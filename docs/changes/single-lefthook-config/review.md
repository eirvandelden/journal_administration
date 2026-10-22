# Review: single-lefthook-config

## Round 1 — 2026-10-20T07:57:52Z — e8fa8cd

No `REVIEW.md` or `REVIEW.local.md` at the repository root, so the reviewer defaults apply: Bugs, Security, Compliance.

- [ ] Nit: The `selector-class-pattern` regex also accepts BEM forms (`block__element`, `block--modifier`). The plan and the rule's own message say "kebab-case, or field_with_errors", and no stylesheet uses a BEM selector. Drop the two optional `__`/`--` groups, or name BEM in the message and the plan. — `stylelint.config.mjs:6` → fixed (Match class selector regex to kebab-case message)

### Bugs

No bug found. `bin/lefthook dump` shows the dotfiles defaults merged with the repository checks. Each repository job appears once under a non-colliding name. The four duplicates (`rubocop` twice, `brakeman`, `bundle-audit`, `minitest`) carry `skip: true`. Both `yamllint` jobs keep the dotfiles `run`/`glob` plus the `config/locales/**` exclude. The `i18n-normalized` glob list now matches `config/locales/en.yml`.

### Security

No finding. `extends:` names one exact path under the user's own home directory, not a glob over `/Users/*`. The removed `remotes:` entry drops a network fetch. The dotfiles `stylelint`/`eslint` jobs run `npx --no`, so they never download a package. All 175 new `yarn.lock` entries resolve from `registry.yarnpkg.com`. `yarn install --frozen-lockfile` succeeds, so the CI `lint_erb` job keeps working.

### Compliance

- One lefthook config, `lefthook-local.yml` gone → `git ls-files` lists only `lefthook.yml`. Proved.
- `lefthook dump` shows `pre-commit`, `pre-push`, `post-merge`, `post-rewrite` → present, plus `migrations`. Proved.
- A pull that changes `db/schema.rb` runs migrations → reviewer re-ran the plan's `pull-check merge schema` shape in scratch clones through the global shim: the fake `rails` ran. Proved.
- A rebase pull runs migrations → same harness, `git pull --rebase` with a local commit: the fake `rails` ran. Proved.
- A pull that leaves `db/schema.rb` alone runs no migration → README-only pull: the marker stayed empty. Proved.
- Every old check runs, none twice → dump matches the plan's Proof list exactly; no `herb` job remains. Proved.
- `yarn stylelint` and `yarn eslint` pass → `yarn stylelint "app/assets/stylesheets/**/*.css"` and `yarn eslint .` exit 0. Proved.
- A normalized locale commit passes `yamllint` and `i18n-normalized` → the dump shows the exclude on both `yamllint` jobs; `commit-check locale` was not re-run by the reviewer. Plausible from config.
- The two layouts pass `erb_lint` → `erb_lint --lint-all` reports no errors; `herb-lint app/views/` is clean. Proved.
- Contributors without the dotfiles are not broken (plan Proof) → the stubs carry `run: "true"`; not re-run by the reviewer.
- JavaScript edits keep the pages working (plan Proof, browser check) → no record of the browser check in the change folder. The code reading holds: `turbo.min.js` exports `Turbo`, and `importmap.rb` pins it. Not re-run by the reviewer.
- No existing test was weakened, skipped or deleted. The plan names no new test file; its Proof uses scratch scripts and a browser check.

Checks run at `e8fa8cd`: `bin/rails test` 1045 runs, 0 failures, 0 errors, 0 skips; Brakeman no warnings; bundler-audit no vulnerabilities; stylelint, eslint, erb_lint, herb-lint, yamllint on `lefthook.yml` all clean.

## Round 2 — 2026-10-22T06:14:43Z — a03213f

No `REVIEW.md` or `REVIEW.local.md` at the repository root, so the reviewer defaults apply: Bugs, Security, Compliance, Design.

- [ ] Important: The branch no longer fits `origin/main` (`552a8c7`), which replaced yarn with npm in #349. A trial merge (`git merge-tree HEAD origin/main`) stops on two modify/delete conflicts: `.lefthook.yml` (deleted here, changed to `npx --no herb-lint` on `main`) and `yarn.lock` (changed here, deleted on `main`). After any resolution, `lefthook.yml` still runs `yarn run herb-lint` at lines 19, 20 and 47, so `main`'s `JavascriptPackageManagerTest` "names yarn nowhere outside data" fails. `main`'s `package-lock.json` holds none of the five new devDependencies, so the CI `lint_erb` job's `npm ci` refuses the out-of-sync lockfile. Fix: rebase onto `origin/main` (sync skill); drop this branch's `yarn.lock` change; add the five approved packages with `npm install --save-dev` so `package-lock.json` carries them; change the three `yarn run herb-lint` strings to `npx --no herb-lint`, as `main`'s `.lefthook.yml` does; keep `.lefthook.yml` deleted. Update the intent's Constraints and the plan to name npm instead of yarn: the package approval stands, only the installer changes. — `lefthook.yml:19` → fixed (Run herb-lint through npx and lock the lint packages with npm)

### Bugs

One finding, above. Round 1's nit holds: `stylelint.config.mjs:6` now accepts only kebab-case or `field_with_errors`, which matches its message. `npx --no stylelint "app/assets/stylesheets/**/*.css"` and `npx --no eslint .` exit 0 at `a03213f`. No other line changed since round 1.

### Security

No finding for this branch. The dotfiles `stylelint` and `eslint` jobs run `npx --no`, so they never download a package. The dotfiles `browserslist` job runs `npx browserslist` without `--no`, and this repository has a `.browserslistrc` but no local `browserslist` binary. A commit or push that touches `.browserslistrc` now makes npx fetch the latest `browserslist` from the registry. The dotfiles own that job and the intent puts dotfiles changes out of scope, so it is a dotfiles follow-up, not a fix here.

### Compliance

- Round 1's Compliance list still holds at `a03213f`: the only new commit edits one regex in `stylelint.config.mjs`.
- The intent's constraint "installed with yarn" and the plan's yarn steps now contradict `main`. The rebase in the finding above changes the installer, which the intent and the plan must record before the branch lands.
- The plan's browser check of the JavaScript edits still has no record in the change folder. Not re-run by the reviewer.

### Design

No finding. One `lefthook.yml` with an exact `extends:` path, non-colliding repository names and `run: "true"` stubs stays the simplest shape that works with and without the dotfiles. The two linter configs are short and hold one Rails exception each, with a comment that says why.

Checks run at `a03213f`: stylelint and eslint clean; `git merge-tree HEAD origin/main` reports the two conflicts above. The test suite, Brakeman and bundler-audit were not re-run: no Ruby or Gemfile change since round 1.

## Round 3 — 2026-10-22T06:20:11Z — 9812997

No `REVIEW.md` or `REVIEW.local.md` at the repository root, so the reviewer defaults apply: Bugs, Security, Compliance, Design.

No open finding. Round 2's Important finding holds as fixed: the branch sits on `origin/main` `552a8c7`, `yarn.lock` and `.lefthook.yml` are gone, and `lefthook.yml` runs `npx --no herb-lint` at all three places.

### Bugs

No bug found. `npm ci --dry-run` succeeds, and `npm install --package-lock-only` leaves `package-lock.json` unchanged, so the CI `lint_erb` job's `npm ci` accepts it. `npm ls` shows the five approved packages at the planned versions. `git grep -i yarn` hits only `docs/changes` and the package manager test itself, both excluded by `JavascriptPackageManagerTest`. Since round 2, `lefthook.yml` changed only in the three herb strings; every other file in the branch diff matches round 2.

### Security

No new finding. All 208 `resolved` entries in `package-lock.json` point at `registry.npmjs.org`. `extends:` still names one exact path. Round 2's `browserslist` note (`npx` without `--no` in the dotfiles job) stays a dotfiles follow-up, out of scope here.

### Compliance

- One lefthook config, `lefthook-local.yml` gone → `git ls-files` lists only `lefthook.yml`. Proved.
- `lefthook dump` shows `pre-commit`, `pre-push`, `post-merge`, `post-rewrite` → present, plus `migrations`. Proved.
- A pull that changes `db/schema.rb` runs migrations → reviewer re-ran `pull-check merge schema` at `9812997` through the global shim: marker holds `MIGRATE`. Proved.
- A rebase pull runs migrations → `pull-check rebase schema`: marker holds `MIGRATE`. Proved.
- A pull that leaves `db/schema.rb` alone runs no migration → `pull-check merge other`: marker empty. Proved.
- Every old check runs, none twice → the dump matches the plan's Proof list: `rubocop-app`, `herb-lint`, `i18n-normalized` in `pre-commit`; `rubocop-app`, `brakeman-app`, `bundler_audit`, `tests`, `herb-lint-full`, `herb-analyze`, `i18n-normalized` in `pre-push`; `rubocop`, `brakeman`, `bundle-audit`, `minitest` skipped; no `herb` job. Proved.
- `npx --no stylelint` and `npx --no eslint` pass → both exit 0 (`"app/assets/stylesheets/**/*.css"` and `.`). Proved.
- A normalized locale commit passes `yamllint` and `i18n-normalized` → both `yamllint` jobs carry the `config/locales/**` exclude in the dump; `commit-check locale` not re-run by the reviewer. Plausible from config.
- The two layouts pass `erb_lint` → `erb_lint --lint-all` reports no errors; `npx --no herb-lint app/views/` exits 0. Proved.
- The plan's browser check of the JavaScript edits still has no record in the change folder. The coordinator must carry that evidence into the pull request account (playbook §7a). Not re-run by the reviewer.
- No existing test was weakened, skipped or deleted.

### Design

No finding. The npm switch changed no structure: one `lefthook.yml`, an exact `extends:` path, non-colliding names, `run: "true"` stubs, two short linter configs with one Rails exception each.

Checks run at `9812997`: `bin/rails test` 1056 runs, 0 failures, 0 errors, 0 skips; rubocop no offenses; Brakeman no warnings; bundler-audit no vulnerabilities; stylelint, eslint, erb_lint, herb-lint and `yamllint lefthook.yml` clean; `npm ci --dry-run` clean; three pull checks as above.
