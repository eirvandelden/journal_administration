require "test_helper"

class SharedFormErrorsPartialTest < ActionView::TestCase
  test "renders nothing for a valid record" do
    render partial: "shared/form_errors", locals: { record: accounts(:checking) }

    assert_empty rendered.strip
  end

  test "renders an alert aside with every message" do
    person = Person.new
    person.valid?

    render partial: "shared/form_errors", locals: { record: person }
    aside = Nokogiri::HTML5.fragment(rendered).at_css("aside[role=alert]")

    assert aside.at_css("h2")
    assert_equal person.errors.full_messages, aside.css("ul li").map(&:text)
  end
end
