require "test_helper"

class SearchesIndexViewTest < ActiveSupport::TestCase
  test "refuses to render a result type it has no partial for" do
    search = Struct.new(:query, :results, :any_results?).new("x", { gadgets: [ Object.new ] }, true)

    error = assert_raises(ActionView::Template::Error) do
      ApplicationController.render(template: "searches/index", assigns: { search: search })
    end

    assert_match "gadgets", error.cause.message
  end
end
