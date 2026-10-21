# Plan: Framework defaults match the Rails version the app runs

From `intent.md` (2026-10-05). Status: accepted.

## Context

`config/application.rb` declares `config.load_defaults 8.0`. The app runs Rails 8.1.4: PR #336 is merged into main. The mismatch came up as review noise. The intent accepts every behaviour change that the 8.1 defaults bring, as long as the suite, the linters, the development boot, key pages and `/mcp` stay as before.

The branch starts at `6b8d63f`, on top of `47e2474`. `origin/main` has moved on since then (people as records, yarn replaced by npm). None of those commits touch `config/application.rb` or `config/initializers/`.

Rails 8.1.4 (`railties-8.1.4/lib/rails/application/configuration.rb`, `when "8.1"`) adds these on top of the 8.0 defaults:

- `yjit = !Rails.env.local?` (the 7.2 defaults set it to `true` everywhere).
- `action_controller.escape_json_responses = false`.
- `action_controller.action_on_path_relative_redirect = :raise`.
- `active_record.raise_on_missing_required_finder_order_columns = true`.
- `active_support.escape_js_separators_in_json = false`.
- `action_view.render_tracker = :ruby`.
- `action_view.remove_hidden_field_autocomplete = true`.

## Design decisions

- Change the version in place: `config.load_defaults 8.1`. Do not add `config/initializers/new_framework_defaults_8_1.rb`. The intent accepts the changes, and a transition file moves the mismatch to another file.
- No new tests. Playbook rule 3 says configuration has no tests, and this change is one configuration line. The existing suite and explicit checks prove it. This departs from `spec.md` (2026-10-13), which asked for a test that pins `loaded_config_version`. That criterion becomes a `bin/rails runner` check. The playbook changed after the spec was written.
- Leave `config/initializers/enable_yjit.rb` alone. It calls `RubyVM::YJIT.enable` after initialisation in every environment. Under the 8.0 defaults it was already redundant. Under 8.1 it keeps YJIT on in development and test, against the new default. Removing it is a separate change.
- No application code changes are expected. On `origin/main` there is no path-relative `redirect_to`. The only `redirect_back` (`app/controllers/accounts/transactions_bulk_controller.rb`) falls back to `accounts_url`, an absolute URL. No model lacks a primary key: `data_migrations` has a string primary key and no model. No test asserts escaped JSON (`<`, `&`, ` `) or `autocomplete` on hidden fields.
- If a default still breaks a check, apply the smallest local fix. Otherwise add an explicit override in `config/application.rb` with a comment that names the reason. A code fix that changes behaviour needs a regression test first (rule 3, bug-fix exception).
- `intent.md` has no `## Decisions` section, so there is nothing to check against.

## Integration points

- `config/application.rb` — the edited line.
- `config/initializers/enable_yjit.rb` — interacts with the new `yjit` default; unchanged.
- `app/controllers/accounts/transactions_bulk_controller.rb` — the only `redirect_back`; affected by `action_on_path_relative_redirect`.
- `app/controllers/assistant_controller.rb` (`/mcp`, `render json:`) — affected by `escape_json_responses` and `escape_js_separators_in_json`. MCP clients parse JSON, so unescaped `<`, `>`, `&`, U+2028 and U+2029 do not change the meaning.
- Lefthook pre-push hooks — run the suite and linters on push.

## Files that change

- `config/application.rb` — `config.load_defaults 8.0` becomes `config.load_defaults 8.1`. The comment above it stays.

## Order of work

1. Rebase the branch onto the latest `origin/main` (`sync` skill). Run `npm install` in the worktree, so the herb linter and the pre-push hook work.
2. Run `bin/rails test -f` once on the 8.0 defaults. Record the result as the baseline. A red test here is pre-existing: name it, do not fix it in this branch (rule 25).
3. Change `config/application.rb` to `config.load_defaults 8.1`. Clear `tmp/cache/bootsnap`.
4. Check the declared version: `bin/rails runner 'puts Rails.application.config.loaded_config_version'` prints `8.1`.
5. Run the suite: `bin/rails test -f`, then `bin/rails test:system`. On a failure, fix the cause per design decision 5. Do not edit a test to make it pass.
6. Run the linters: `bundle exec rubocop`, `npx @herb-tools/linter app/views/`, `bundle exec brakeman --no-pager -q`, `bundle exec bundler-audit check`, `bundle exec i18n-tasks normalize` (then `git diff --exit-code config/locales`).
7. Boot check, from the worktree: copy the development database in, then start the app with `DISABLE_SSL=1` on port 3001 and open `http://127.0.0.1:3001`. Sign in. Load the dashboard, the accounts list, one account page and the transactions list. On an account page, press "update transactions" and confirm it returns to that account page. POST a `tools/list` JSON-RPC request to `/mcp` with a valid assistant token and the `ASSISTANT_HOST` host. Expect a 200 with the tool list. Confirm the log has no framework-defaults deprecation warning. Do not commit a re-dumped `db/schema.rb`.
8. Re-read the diff: only the `config/application.rb` line. Commit it alone.

## Out of scope

- Removing or changing `config/initializers/enable_yjit.rb`.
- Other leftover initializers (`cookies_serializer.rb`, `wrap_parameters.rb`, `application_controller_renderer.rb`).
- `config/environments/*.rb` — not edited (playbook rule 13 for production).
- Any Rails or gem version change.
- New tests for existing behaviour, such as the untested bulk-update controller.

## Risks

- Production behaviour changes without a staged rollout. YJIT stays on in production through the default and the initializer. JSON bodies stop escaping HTML characters. No HTML page embeds `render json:` output, so this opens no XSS path today.
- `raise_on_missing_required_finder_order_columns`: `first` or `last` on a model without a primary key or `implicit_order_column` now raises. No such model exists; the suite confirms.
- `action_on_path_relative_redirect = :raise`: a referer without a scheme and host now raises instead of logging. Browsers send absolute referers, so only a hand-made request hits it. Accepted.
- `render_tracker = :ruby` changes how template digests are computed. Fragment caches keyed on digests get new keys once, after the deploy. Accepted: a one-time cache miss.
- The bulk-update redirect has no automated test. Step 7 checks it by hand. Adding a test is out of scope.
- Rejected: a `new_framework_defaults_8_1.rb` transition file (keeps the mismatch); a test that pins the defaults version (rule 3: configuration has no tests).

## Proof

- The application configuration declares the 8.1 framework defaults → check: `bin/rails runner 'puts Rails.application.config.loaded_config_version'` prints `8.1`.
- The test suite and all linters stay green → check: `bin/rails test`, `bin/rails test:system` and the five linter commands in step 6 all exit 0.
- The app boots in development, and key pages and `/mcp` respond as before → check: the existing `test/integration/assistant_test.rb` and `test/integration/accounts_index_test.rb` pass, plus the manual boot in step 7.

Per changed file, the unit tests expected:
- `config/application.rb`: none (configuration).

Test setup: none.

---
Domain skills applied: rails-upgrade, rails-testing.
