# Plan: Add stylelint and eslint with working configs

From `intent.md` (2026-10-22). Status: accepted.

## Context

- `stylelint-config-standard` flags 14 errors in 4 files. `--fix` corrects 5 of them at 3 places: an empty line between `@import` rules (`application.css`), `min-width` range notation (`local/layout/application_page.css`), and the `rgba(0, 0, 0, 0.2)` value (`local/modules/search_dialog.css`).
- The other 9 are `selector-class-pattern` on 6 `.field_with_errors` selectors and `selector-id-pattern` on 3 `#error_explanation` selectors, all in `local/modules/form_errors.css`. Rails generates both names.
- `@eslint/js` recommended with `globals.browser` and ES modules flags 3 errors: `Turbo` undefined in `app/javascript/application.js`, `require` undefined in `app/javascript/channels/index.js`, and unused `_error` in `app/javascript/controllers/clipboard_controller.js`.
- `app/javascript/channels/index.js` is never loaded: `config/importmap.rb` does not pin it, and its `require.context` cannot run under importmap.
- `erb_lint` flags one `SpaceInHtmlTag` offence in each of `app/views/layouts/application.html.erb` and `app/views/layouts/admin.html.erb`: the newline before the closing `>` of the multi-line `<html` tag.

## Design decisions

- The five approved packages go into `package.json` `devDependencies` with caret ranges, through npm, and `package-lock.json` changes with them.
- `stylelint.config.mjs` extends `stylelint-config-standard`. It allows kebab-case or the one Rails name per rule (`field_with_errors`, `error_explanation`), with a comment that Rails generates them. The other 5 errors are fixed in the CSS with `stylelint --fix`.
- `eslint.config.mjs` is a flat config: `@eslint/js` recommended, `globals.browser`, `sourceType: "module"`, for `**/*.js`.
- `application.js` imports `{ Turbo }` by name, `channels/index.js` is deleted, and `clipboard_controller.js` uses an optional catch binding.
- In both layouts the closing `>` of the `<html` tag moves to the end of the `data-theme` line.

## Files that change

- `package.json`, `package-lock.json`, `stylelint.config.mjs`, `eslint.config.mjs`.
- `app/assets/stylesheets/application.css`, `app/assets/stylesheets/local/layout/application_page.css`, `app/assets/stylesheets/local/modules/search_dialog.css`.
- `app/javascript/application.js`, `app/javascript/channels/index.js` (deleted), `app/javascript/controllers/clipboard_controller.js`.
- `app/views/layouts/application.html.erb`, `app/views/layouts/admin.html.erb`.

No lefthook file changes.

## Order of work

1. Fix the `<html` tag in both layouts and check `erb_lint` and `herb-lint`.
2. Add stylelint, its config and the CSS fixes.
3. Add eslint, its config and the JS fixes.
4. Restore the lefthook files to the state on `main`.
5. Run rubocop, herb-lint, brakeman, bundler-audit and the test suite.

## Risks

- A new Rails-generated snake_case name in the CSS fails the check and needs its own entry or a rename.
- `application.js` names `Turbo` through the import. It is the same module object that `turbo-rails` puts on `window.Turbo`.

## Proof

- `npx --no stylelint "app/assets/stylesheets/**/*.css"` and `npx --no eslint .` exit 0.
- `erb_lint` passes on both layouts.
- `git diff origin/main --name-only` lists no lefthook file.
- `npm ci --dry-run` passes, so CI's `npm ci` keeps working.

Per changed file, the unit tests expected: none. The changes are configuration, notation-only CSS edits and small JS edits.

Domain skills applied: dependencies (npm, caret ranges, approval recorded in the intent).
