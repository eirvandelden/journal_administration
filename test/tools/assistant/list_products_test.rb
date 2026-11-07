require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ListProductsTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "lists products with brand and type" do
    text = said(Assistant::ListProducts.call(server_context: nil))

    assert_includes text, "#{products(:ah_ribbelchips).id}: AH Naturel Ribbelchips, brand AH, type Naturel chips"
  end

  test "flags the products still unclassified" do
    text = said(Assistant::ListProducts.call(server_context: nil))

    assert_includes text, "#{products(:andrelon_shampoo).id}: Andrelon shampoo, brand none, type none (unclassified)"
  end
end
