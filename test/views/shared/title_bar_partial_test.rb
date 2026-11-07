require "test_helper"
require_relative "../../test_helpers/view_menu"

class SharedTitleBarPartialTest < ActionView::TestCase
  setup { view.extend(ViewMenu) }

  test "renders one h1" do
    render layout: "shared/title_bar", locals: { title: "Rekeningen" } do
      "<a href='/x'>Nieuw</a>".html_safe
    end
    fragment = Nokogiri::HTML5.fragment(rendered)

    assert_equal [ "Rekeningen" ], fragment.css("header > h1").map(&:text)
    assert_equal "Nieuw", fragment.at_css("header > nav a").text
  end

  test "holds only the search button without a block" do
    render partial: "shared/title_bar", locals: { title: "Rekeningen" }
    nav = Nokogiri::HTML5.fragment(rendered).at_css("nav")

    assert_equal 0, nav.css("a").size
    assert_equal "click->search-dialog#open", nav.at_css("button")["data-action"]
  end

  test "renders the back link first" do
    view.menu.define_singleton_method(:back) { |fallback| Appkit::Menu::Link.new(label: "Rekeningen", path: fallback) }

    render partial: "shared/title_bar", locals: { title: "Rekening", back: "/accounts" }
    link = Nokogiri::HTML5.fragment(rendered).at_css("nav a")

    assert_equal "‹ Rekeningen", link.text
    assert_equal "/accounts", link["href"]
  end
end
