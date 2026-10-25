require "test_helper"
require_relative "../test_helpers/assistant_requests"

class AssistantProductsTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "classifying a product takes it off the unclassified list" do
    product = products(:andrelon_shampoo)

    assert_includes ask_assistant("list_products", unclassified: true), "Andrelon shampoo"

    ask_assistant("classify_product", product_id: product.id, brand: "Andrelon",
      product_type_id: product_types(:dishwashing_liquid).id)

    assert_equal [ "Andrelon", product_types(:dishwashing_liquid) ], [ product.reload.brand, product.product_type ]
    assert_not_includes ask_assistant("list_products", unclassified: true), "Andrelon shampoo"
  end

  test "the assistant manages product types" do
    ask_assistant("create_product_type", name: "Shampoo", category_id: categories(:household).id)
    type = ProductType.find_by!(name: "Shampoo")

    ask_assistant("update_product_type", product_type_id: type.id, category_id: categories(:groceries).id)

    assert_equal categories(:groceries), type.reload.category
    assert_includes ask_assistant("list_product_types"), "#{type.id}: Shampoo"
    assert_includes ask_assistant("show_product_type", product_type_id: product_types(:naturel_chips).id),
      "AH Naturel Ribbelchips"
  end
end
