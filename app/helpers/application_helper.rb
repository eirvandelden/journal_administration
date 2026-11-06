module ApplicationHelper
  include VersionHelper

  #: () -> Array[Array[untyped]]
  def locale_options_for_select
    User.locales.keys.map do |locale|
      [ I18n.t("language_names.#{locale}", default: locale), locale ]
    end
  end
end
