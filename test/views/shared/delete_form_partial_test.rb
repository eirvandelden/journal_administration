require "test_helper"

class SharedDeleteFormPartialTest < ActionView::TestCase
  test "renders an empty DELETE form with the dom_id delete id" do
    account = accounts(:checking)

    render partial: "shared/delete_form", locals: { record: account, url: account_path(account) }
    form = Nokogiri::HTML5.fragment(rendered).at_css("form")

    assert_equal dom_id(account, :delete), form["id"]
    assert_equal account_path(account), form["action"]
    assert_equal "delete", form.at_css("input[name=_method]")["value"]
    assert_empty form.element_children.reject { |node| node["type"] == "hidden" }
  end
end
