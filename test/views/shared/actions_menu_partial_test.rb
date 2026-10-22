require "test_helper"

class SharedActionsMenuPartialTest < ActionView::TestCase
  test "renders a details menu with the translated summary" do
    render layout: "shared/actions_menu" do
      "<ul><li><a href='/x'>Doe iets</a></li></ul>".html_safe
    end
    details = Nokogiri::HTML5.fragment(rendered).at_css("details")

    assert_equal I18n.t("common.actions_menu"), details.at_css("summary").text.strip
    assert_equal "Doe iets", details.at_css("ul a").text
  end
end
