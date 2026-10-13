# Spec: Framework defaults match the Rails version the app runs

From `intent.md` (2026-10-05). Status: accepted.

## Flagged concerns

- Playbook rule 17 asks for a test before code. This change is a one-line config edit. Its proof is the existing suite plus one test that pins the declared defaults version.
- Playbook rule 13 treats `config/environments/production.rb` as high-risk. This change does not edit it. `load_defaults 8.1` still alters production behaviour (see Requirements 3).

## Requirements

1. `config/application.rb` declares `config.load_defaults 8.1`.
2. No other configuration file changes unless an 8.1 default breaks a success check. Then the fix is the smallest local change, or an explicit override with a comment naming the reason.
3. The 8.1 defaults take effect in every environment. Rails 8.1.4 sets these on top of the 8.0 defaults:
   - `yjit` is on only outside local environments (`!Rails.env.local?`).
   - `action_controller.escape_json_responses = false`.
   - `action_controller.action_on_path_relative_redirect = :raise`.
   - `active_record.raise_on_missing_required_finder_order_columns = true`.
   - `active_support.escape_js_separators_in_json = false`.
   - `action_view.render_tracker = :ruby`.
   - `action_view.remove_hidden_field_autocomplete = true`.
4. The test suite and all linters stay green: rubocop, herb, brakeman, bundler-audit, i18n-tasks.
5. The app boots in development. Key pages and the `/mcp` endpoint respond as before.

## Design decisions

- Bump the version in place. Do not add `config/initializers/new_framework_defaults_8_1.rb`. The intent accepts the behaviour changes, and a transition file would leave the same mismatch in another place.
- Leave `config/initializers/enable_yjit.rb` alone. It enables YJIT after initialisation in every environment, so it overrides the new `yjit` default. Removing it is a separate change.
- The only redirect helper in `app/` is `redirect_back fallback_location: accounts_url`, with an absolute URL. It cannot trigger the `:raise` for path-relative redirects. Verification confirms this rather than assuming it.
- No application code changes are expected. The `render_tracker`, finder-order and hidden-field defaults are checked by the suite and by loading pages, not by new code.

## Integration points

- `config/application.rb`: the single edited line.
- `config/initializers/enable_yjit.rb`: interacts with the new `yjit` default, unchanged.
- `app/controllers/accounts/transactions_bulk_controller.rb`: the only `redirect_back` use.
- `/mcp` endpoint: JSON responses, affected by `escape_json_responses`.
- Lefthook pre-push hooks, which run tests and linters.

## Acceptance criteria

- The application reports 8.1 as its loaded defaults version: `Rails.application.config.loaded_config_version` equals `8.1`.
- Loading the application in the test environment raises no error and prints no deprecation warning about framework defaults.
- Visiting the accounts list as a signed-in user returns a successful page.
- Bulk-updating transaction categories, with or without a referer, redirects to a valid page.
- A forms page renders its form and submits it without error (hidden-field `autocomplete` removal).
- A JSON request to `/mcp` with a valid assistant token and host returns the same response as before.
- `bin/rails test` passes with zero failures.
- Rubocop, herb, brakeman, bundler-audit and `i18n-tasks normalize` all pass.
- `bin/dev` boots and serves the sign-in page.

---
Domain skills applied: rails-upgrade, rails-testing.
