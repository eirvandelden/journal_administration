require "test_helper"

class SharedTitleBarPartialTest < ActionView::TestCase
  test "renders one h1" do
    render layout: "shared/title_bar", locals: { title: "Rekeningen" } do
      "<a href='/x'>Nieuw</a>".html_safe
    end
    fragment = Nokogiri::HTML5.fragment(rendered)

    assert_equal [ "Rekeningen" ], fragment.css("header > h1").map(&:text)
    assert_equal "Nieuw", fragment.at_css("header > nav a").text
  end

  test "leaves the nav out without a block" do
    render layout: "shared/title_bar", locals: { title: "Rekeningen" } do
      ""
    end

    assert_nil Nokogiri::HTML5.fragment(rendered).at_css("nav")
  end
end
