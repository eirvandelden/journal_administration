require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ListProductTypesTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "lists types with their category" do
    text = said(Assistant::ListProductTypes.call(server_context: nil))

    assert_includes text, "#{product_types(:naturel_chips).id}: Naturel chips, books to Groceries"
  end
end
