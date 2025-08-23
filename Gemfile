source "https://rubygems.org"

ruby file: ".ruby-version"

# Needs to be loaded first
gem "dotenv-rails" # Read .env files and make available in Rails

gem "rails", "~> 7.1"

# Drivers
gem "sqlite3", "~> 1.4" # Use sqlite3 as the database for Active Record
gem "redis", "~> 4.0" # Use Redis for Action Cable

# Deployment
gem "kamal", require: false     # Deployment
gem "puma" # Use Puma as the app server

# Jobs
# TODO: SolidJobs

# Front-end
gem "haml-rails"                  # Awesome templating engine
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails" # Turbo makes navigating your web application faster.

# Other
gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false    # Reduces boot times through caching; required in config/boot.rb
gem "bundler-audit"
gem "csv"
gem "data_migrate"                # Migrate data alongside schema
gem "flutie"                      # Flutie provides some utility view helpers for use with Rails applications.
gem "jbuilder" # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "pagy" # The Ultimate Pagination Ruby Gem
gem "symbol-fstring", require: "fstring/all" # Performance improvement
gem "thruster"
gem "useragent", github: "basecamp/useragent"

group :development, :test do
  gem "debug", ">= 1.0.0"
  gem "brakeman", require: false
end


group :development do
  gem "rails-erd", require: false
  gem "web-console" # Access an interactive console on exception pages or by calling 'console' anywhere.

  # Linting and formatting
  gem "rubocop-capybara", require: false
  gem "rubocop-minitest", require: false
  gem "rubocop-obsession", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "capybara"                   # Adds support for Capybara system testing and selenium driver
  gem "selenium-webdriver"
  gem "webdrivers"                 # Easy installation and use of web drivers to run system tests with browsers
end
