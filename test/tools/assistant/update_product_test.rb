require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::UpdateProductTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "replaces a brand and product type already set" do
    product = products(:ah_ribbelchips)

    text = said(update(product, brand: "Lay's", product_type_id: product_types(:dishwashing_liquid).id))

    assert_equal [ "Lay's", product_types(:dishwashing_liquid) ], [ product.reload.brand, product.product_type ]
    assert_includes text, "Updated product #{product.id}: AH Naturel Ribbelchips, brand Lay's, type Dishwashing liquid"
  end

  test "renames a product and keeps what it was not asked to change" do
    product = products(:ah_ribbelchips)

    update(product, name: "AH Ribbelchips naturel")

    assert_equal [ "AH Ribbelchips naturel", "AH", product_types(:naturel_chips) ],
      [ product.reload.name, product.brand, product.product_type ]
  end

  test "refuses an unknown product" do
    assert refused_response?(Assistant::UpdateProduct.call(product_id: 0, brand: "AH", server_context: nil))
  end

  test "refuses an unknown product type" do
    response = update(products(:ah_ribbelchips), product_type_id: 0)

    assert refused_response?(response)
    assert_equal product_types(:naturel_chips), products(:ah_ribbelchips).reload.product_type
  end

  test "passes on the books' refusal" do
    response = update(products(:ah_ribbelchips), name: "")

    assert refused_response?(response)
    assert_includes said(response), "Name"
  end

  private

  def update(product, **changes)
    Assistant::UpdateProduct.call(product_id: product.id, server_context: nil, **changes)
  end
end
