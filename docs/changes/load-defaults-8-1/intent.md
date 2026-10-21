# Intent: Framework defaults match the Rails version the app runs

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

`config/application.rb` declares `config.load_defaults 8.0`, but the app runs Rails 8.1 (8.1.3.1 on main, 8.1.4 once PR #336 merges). The declared defaults version does not match the framework version. It reads as a leftover from the 8.1 upgrade and came up as review noise on PR #336.

## Proposed outcome

The declared framework defaults version matches the Rails version the app runs, so the mismatch no longer comes up in reviews.

Success looks like:

- The application configuration declares the 8.1 framework defaults.
- The test suite and all linters (rubocop, herb, brakeman, bundler-audit, i18n-tasks) stay green.
- The app boots in development, and key pages and the `/mcp` endpoint respond as before.

## Affected users and systems

- Developers and reviewers reading the app configuration.
- The Rails application boot configuration, in every environment.

## Constraints

- Any framework behaviour change that comes with the 8.1 defaults is acceptable, as long as the success checks above hold.
- Starts after PR #336 merges; branches off main, not off `rails-8-1-4`.

## Open questions

None.
