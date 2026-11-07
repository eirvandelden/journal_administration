require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::UpdateProductTypeTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "renames a type or moves it to another category" do
    type = product_types(:naturel_chips)

    Assistant::UpdateProductType.call(product_type_id: type.id, name: "Crisps",
      category_id: categories(:household).id, server_context: nil)

    assert_equal [ "Crisps", categories(:household) ], [ type.reload.name, type.category ]
  end

  test "refuses an unknown type" do
    assert refused_response?(Assistant::UpdateProductType.call(product_type_id: 0, server_context: nil))
  end
end
