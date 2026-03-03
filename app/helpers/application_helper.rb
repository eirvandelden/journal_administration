module ApplicationHelper
  include Pagy::Frontend

  def locale_options_for_select
    User.locales.keys.map do |locale|
      [ I18n.t("language_names.#{locale}", default: locale), locale ]
    end
  end
end
