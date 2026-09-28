# Plan

1. Loosen the `rails` constraint in the Gemfile only if it blocks resolving 8.1.4.
2. Run `bundle update rails --conservative`.
3. Run the test suite, rubocop on touched files, `bundle exec bundler-audit check --update`, and `bin/brakeman` if available.
4. Boot check: confirm `Rails.version` prints 8.1.4.
