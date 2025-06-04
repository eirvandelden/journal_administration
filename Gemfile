source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby file: ".ruby-version"

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
gem "propshaft"
gem "importmap-rails", "~> 1.2"
gem "puma" # Use Puma as the app server
gem "rails", "~> 7.1"
gem "sqlite3", "~> 1.4" # Use sqlite3 as the database for Active Record
gem "symbol-fstring", require: "fstring/all" # Performance improvement
gem "redis", "~> 4.0" # Use Redis for Action Cable
gem "turbo-rails" # Turbo makes navigating your web application faster.
gem "stimulus-rails"

# BUGS
gem "psych", "< 4.0"
gem "rexml"

group :development, :test do
  gem "debug", ">= 1.0.0"
end

group :development do
  gem "kamal", require: false     # Deployment
  gem "listen"
  gem "rails-erd"
  gem "spring-watcher-listen"
  gem "spring"                    # Spring speeds up development by keeping your application running in the background.
  gem "web-console"               # Access an interactive console on exception pages or by calling 'console' anywhere.
end

group :test do
  gem "capybara"                   # Adds support for Capybara system testing and selenium driver
  gem "selenium-webdriver"
  gem "webdrivers"                 # Easy installation and use of web drivers to run system tests with browsers
end
