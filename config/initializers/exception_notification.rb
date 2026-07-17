# frozen_string_literal: true

if Rails.env.production?
  ExceptionNotification::Once::Campfire.install!(
    webhook_url: ENV.fetch("CAMPFIRE_WEBHOOK_URL"),
    app_name: ENV.fetch("APP_NAME", Rails.application.class.module_parent_name),
    background: :active_job
  )
end
