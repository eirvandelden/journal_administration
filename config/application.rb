require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JournalAdministration
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end

  Raven.configure do |config|
    config.dsn = 'https://afb8d771ad114eddbcd7b14546680ad0:4b94b49acc9b4c7cab58ab8a00dd9e15@sentry.io/1778246'
  end
end
