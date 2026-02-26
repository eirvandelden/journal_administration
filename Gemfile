source "https://gem.coop"

ruby file: ".ruby-version"

# Needs to be loaded first
gem "dotenv-rails", "~> 3.2" # Read .env files and make available in Rails

gem "rails", "~> 8.0"
gem "faultline", git: "https://github.com/dlt/faultline.git"

# Drivers
gem "sqlite3", ">= 2.0" # Use sqlite3 as the database for Active Record
gem "redis", "~> 5.0" # Use Redis for Action Cable

# Deployment
gem "kamal", require: false     # Deployment
gem "puma" # Use Puma as the app server

# Jobs
# TODO: SolidJobs

# Front-end
gem "haml-rails"                  # Awesome templating engine
gem "importmap-rails"
gem "mvpa-css", github: "eirvandelden/mvpa.css"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails" # Turbo makes navigating your web application faster.

# Other
gem "bcrypt", "~> 3.1"
gem "bootsnap", require: false    # Reduces boot times through caching; required in config/boot.rb
gem "bundler-audit"
gem "csv"
gem "data_migrate"                # Migrate data alongside schema
gem "flutie"                      # Flutie provides some utility view helpers for use with Rails applications.
gem "jbuilder" # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "pagy", "~> 9.3" # The Ultimate Pagination Ruby Gem
gem "symbol-fstring", require: "fstring/all" # Performance improvement
gem "thruster"

group :development, :test do
  gem "debug", ">= 1.0.0"
  gem "brakeman", require: false
end


group :development do
  gem "rails-erd", require: false
  gem "web-console" # Access an interactive console on exception pages or by calling 'console' anywhere.

  # Localization
  gem "i18n-tasks"

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
end
