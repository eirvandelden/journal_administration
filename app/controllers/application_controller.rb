class ApplicationController < ActionController::Base
  include Authentication, Authorization, VersionHeaders
  include Pagy::Backend

  protect_from_forgery with: :exception
  around_action :switch_locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def switch_locale(&action)
      locale = Current.user.try(:locale) || I18n.default_locale
      I18n.with_locale(locale, &action)
    end
end
