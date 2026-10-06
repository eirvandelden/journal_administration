# Intent: Update dependencies to their latest versions

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

The app runs on older releases of its gems, its ERB linter, Ruby and Bundler. On 2026-10-06, `bundle outdated` lists 27 gems behind their newest release, `yarn outdated` lists `@herb-tools/linter` 0.10.4 against 0.11.0, the app pins Ruby 4.0.6 while 4.0.7 is out, and `Gemfile.lock` is bundled with Bundler 2.7.2 while 4.0.22 is out. Six Dependabot PRs (#331, #332, #333, #338, #339, #340) each cover one piece of this, and some already lag behind newer releases. The household misses bug and security fixes until each piece lands on its own.

## Proposed outcome

One change brings every dependency to its newest release that the app's own and its dependencies' constraints allow. The books, receipts, budgets, chattels and the assistant's `/mcp` access behave exactly as before. All tests and linters stay green, and the updated gems print no new deprecation warnings.

## Affected users and systems

- Family members using the web app, and the assistant reading and filing transactions through `/mcp` (the `mcp` gem moves from 1.5.1 to 1.7.0).
- The production container: the Dockerfile's `RUBY_VERSION` moves to 4.0.7.
- CI and the lefthook pre-push hooks: herb gem and `@herb-tools/linter` move to 0.11, which can add or change ERB lint rules.
- Local development under `rv`: `.ruby-version` moves to 4.0.7, which is already installed.

## Constraints

- Never skip a major version. Bundler 3 was never released; 2.7 is the transition release to 4.0, so 2.7.2 → 4.0 skips nothing.
- Rails 8.1.4 is the newest Rails and is already installed. `activestorage` requires `marcel ~> 1.0`, so `marcel` stays on 1.x even though 2.1.0 exists.
- The herb gem and the `@herb-tools/linter` npm package move together, so the Ruby-side and Node-side ERB linting agree.
- Etienne approves editing the Dockerfile's `RUBY_VERSION` for this change (rule 13). Any other deploy config change still needs its own approval.
- Etienne approves installing Bundler 4.0.22 into Ruby 4.0.7 (`gem install bundler -v 4.0.22`, rule 8). Ruby 4.0.7 ships with 4.0.20, so the Docker build downloads 4.0.22 too.
- No gem, npm package or GitHub Action gets added or removed.
- Fix deprecation warnings that the updated gems introduce, rather than leaving them behind.

## In scope

- All outdated gems in `Gemfile.lock`, including the personal git gems `appkit` and `mvpa-css` moving to their latest commit.
- `@herb-tools/linter` to 0.11.0, widening the `^0.10.4` constraint in `package.json`.
- Ruby 4.0.6 → 4.0.7: `.ruby-version`, the Dockerfile's `ARG RUBY_VERSION`, and the `RUBY VERSION` section in `Gemfile.lock`.
- Bundler 2.7.2 → 4.0.22: the `BUNDLED WITH` line in `Gemfile.lock`.
- GitHub Actions in `.github/workflows/`: confirm each reference points at its latest release. On 2026-10-06 they already do (`actions/checkout@v7.0.1`, `actions/setup-node@v7`, and `@main` refs), so this changes nothing unless a newer release appears before implementation.
- Fixing new herb offenses in `app/views` and any breakage or deprecation the updates cause.

## Out of scope

- `marcel` 2.x, which Rails' `activestorage` constraint blocks.
- Changing the version constraints in `Gemfile` (`rails ~> 8.0`, `dotenv-rails ~> 3.2`, `bcrypt ~> 3.1`, `geared_pagination ~> 1.2`). None of them blocks a newer release today.
- Closing the overlapping Dependabot PRs. Dependabot closes each one itself once main carries an equal or newer version.
- Deploying the result (rule 13).
- Installing or switching any Ruby or system tool, apart from Bundler 4.0.22.

## Acceptance criteria

- `bundle outdated` lists only `marcel`, held at 1.x by `activestorage`.
- `yarn outdated` lists nothing.
- `.ruby-version`, the Dockerfile's `RUBY_VERSION` and `Gemfile.lock`'s `RUBY VERSION` all say 4.0.7.
- `Gemfile.lock` says `BUNDLED WITH` 4.0.22.
- Every action in `.github/workflows/` points at its latest release.
- `bin/rails test` and the system tests pass.
- `bundle exec rubocop`, herb lint on `app/views/`, Brakeman, `bundler-audit check` and `i18n-tasks normalize` all pass.
- The test run prints no deprecation warning that comes from an updated gem.
- The assistant can still list transactions through `/mcp` (the existing assistant integration test passes).

## Open questions

None.
