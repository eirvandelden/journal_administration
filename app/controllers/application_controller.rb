class ApplicationController < ActionController::Base
  include Authentication, Authorization, VersionHeaders

  protect_from_forgery with: :exception
  around_action :switch_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern, block: -> { block_unsupported_browser }

  private
    def block_unsupported_browser
      return if Rails.env.local? && /Electron/i.match?(request.user_agent)

      render file: Rails.root.join("public/406-unsupported-browser.html"), layout: false, status: :not_acceptable
    end

    def switch_locale(&action)
      locale = Current.user.try(:locale) || I18n.default_locale
      I18n.with_locale(locale, &action)
    end
end
