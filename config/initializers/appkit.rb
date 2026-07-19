# frozen_string_literal: true

Appkit.configure do |config|
  config.app_name = -> { ENV.fetch("APP_NAME", Rails.application.class.module_parent_name) }
  config.email_attribute = :email_address
  config.brand_color = "#0068c9" # mvpa's --color-blue (light theme), see mvpa.css/4_theme/0_colors.css

  # Deactivated users kept their sessions destroyed and email mangled, but were
  # never allowed to authenticate again — preserve that with the old accounts.
  config.user_scope = -> { User.active }

  # The default first_run lambda already matches JA's :administrator role key,
  # but JA also requires a :locale on create, which the login/signup form
  # doesn't collect.
  config.first_run = ->(user_params) { User.create!(user_params.merge(role: :administrator, locale: :en)) }
end
