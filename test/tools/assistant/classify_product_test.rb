require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ClassifyProductTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "sets brand and product type" do
    product = products(:andrelon_shampoo)

    Assistant::ClassifyProduct.call(product_id: product.id, brand: "Andrelon",
      product_type_id: product_types(:dishwashing_liquid).id, server_context: nil)

    assert_not product.reload.unclassified?
  end

  test "refuses an unknown product type" do
    response = Assistant::ClassifyProduct.call(product_id: products(:andrelon_shampoo).id,
      product_type_id: 0, server_context: nil)

    assert refused_response?(response)
  end

  test "passes on the books' refusal" do
    response = Assistant::ClassifyProduct.call(product_id: products(:andrelon_shampoo).id, name: "",
server_context: nil)

    assert refused_response?(response)
    assert_includes said(response), "Name"
  end
end
