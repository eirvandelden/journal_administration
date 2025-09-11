class ApplicationController < ActionController::Base
  include Authentication, Authorization, VersionHeaders
  include Pagy::Backend

  # Disable origin-checking CSRF mitigation
  skip_before_action :verify_authenticity_token
  before_action :locale

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def locale
      I18n.locale = Current.user&.locale || "en"
    end
end
