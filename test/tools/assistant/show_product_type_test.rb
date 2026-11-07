require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ShowProductTypeTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "shows the type with its latest purchase per product" do
    text = said(Assistant::ShowProductType.call(product_type_id: product_types(:naturel_chips).id,
      server_context: nil))

    assert_includes text, "AH Naturel Ribbelchips: paid 1.49"
    assert_includes text, "Lay's Ribbelchips Naturel: paid 1.49"
  end

  test "refuses an unknown type" do
    assert refused_response?(Assistant::ShowProductType.call(product_type_id: 0, server_context: nil))
  end
end
