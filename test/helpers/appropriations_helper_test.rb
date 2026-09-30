require "test_helper"

class AppropriationsHelperTest < ActionView::TestCase
  test "groups appropriations by budget year, newest first, and marks the selected one" do
    options = Nokogiri::HTML5.fragment(grouped_appropriation_options(selected: appropriations(:birthday_etienne)))

    assert_equal %w[2027 2026], options.css("optgroup").map { |group| group["label"] }
    assert_equal [ "Birthday Etienne 2026" ], options.css("option[selected]").map(&:text)
  end
end
