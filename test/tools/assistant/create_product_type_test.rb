require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::CreateProductTypeTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "creates a type booked to a category" do
    Assistant::CreateProductType.call(name: "Shampoo", category_id: categories(:household).id, server_context: nil)

    assert_equal categories(:household), ProductType.find_by!(name: "Shampoo").category
  end

  test "refuses a name already taken" do
    response = Assistant::CreateProductType.call(name: "naturel CHIPS", category_id: categories(:household).id,
      server_context: nil)

    assert refused_response?(response)
  end
end
