source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.4'

gem 'bootsnap', '>= 1.4.2', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'bundle-audit'
gem 'clearance'                   # Rails authentication with email & password.
gem 'data_migrate'                # Migrate data alongside schema
gem 'dotenv-rails'                # Read .env files and make available in Rails
gem 'flutie'                      # Flutie provides some utility view helpers for use with Rails applications.
gem 'haml-rails'                  # Awesome templating engine
gem 'jbuilder', '~> 2.7'          # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'pagy'                        # The Ultimate Pagination Ruby Gem
gem 'pg', '>= 0.18', '< 2.0'      # Use postgresql as the database for Active Record
gem 'puma', '~> 3.11'             # Use Puma as the app server
gem 'rails', '~> 6.0.0'
gem 'sass-rails', '~> 5'          # Use SCSS for stylesheets
gem 'sentry-raven'                # Use sentry to capture exceptions
gem 'turbolinks', '~> 5'          # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'webpacker', '~> 4.0'         # Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'bcrypt', '~> 3.1.7' # Use Active Model has_secure_password
# gem 'image_processing', '~> 1.2' # Use Active Storage variant
# gem 'redis', '~> 4.0' # Use Redis adapter to run Action Cable in production

group :development, :test do
  gem 'byebug'                    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring'                    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'web-console', '>= 3.3.0'   # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
end

group :test do
  gem 'capybara', '>= 2.15'        # Adds support for Capybara system testing and selenium driver
  gem 'selenium-webdriver'
  gem 'webdrivers'                  # Easy installation and use of web drivers to run system tests with browsers
end
