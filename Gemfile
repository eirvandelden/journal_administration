source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

# Needs to be loaded first
gem "dotenv-rails" # Read .env files and make available in Rails

gem "bootsnap", require: false    # Reduces boot times through caching; required in config/boot.rb
gem "bundler-audit"
gem "clearance"                   # Rails authentication with email & password.
gem "data_migrate"                # Migrate data alongside schema
gem "flutie"                      # Flutie provides some utility view helpers for use with Rails applications.
gem "haml-rails"                  # Awesome templating engine
gem "jbuilder" # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "pagy" # The Ultimate Pagination Ruby Gem
gem "puma"                        # Use Puma as the app server
gem "rails"
gem "sass-rails"                  # Use SCSS for stylesheets
gem "sentry-raven"                # Use sentry to capture exceptions
gem "sqlite3", "~> 1.4" # Use sqlite3 as the database for Active Record
gem "symbol-fstring", require: "fstring/all" # Performance improvement
gem "turbolinks"                  # Turbolinks makes navigating your web application faster.
gem "webpacker"                   # Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker

# BUGS
gem "psych", "< 4.0"

group :development, :test do
  gem "debug", ">= 1.0.0"
end

group :development do
  gem "listen"
  gem "spring"                    # Spring speeds up development by keeping your application running in the background.
  gem "spring-watcher-listen"
  gem "web-console"               # Access an interactive console on exception pages or by calling 'console' anywhere.
end

group :test do
  gem "capybara"                   # Adds support for Capybara system testing and selenium driver
  gem "selenium-webdriver"
  gem "webdrivers"                 # Easy installation and use of web drivers to run system tests with browsers
end
