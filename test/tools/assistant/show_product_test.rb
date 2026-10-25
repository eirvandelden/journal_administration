require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ShowProductTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "shows the product with its purchases" do
    text = said(Assistant::ShowProduct.call(product_id: products(:dreft_dishwashing_liquid).id, server_context: nil))

    assert_includes text, "Dreft afwasmiddel"
    assert_includes text, "paid 3.49"
  end

  test "refuses an unknown product" do
    assert refused_response?(Assistant::ShowProduct.call(product_id: 0, server_context: nil))
  end
end
