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

    assert_includes ask_assistant("list_unclassified_products"), "Andrelon shampoo"

    ask_assistant("classify_product", product_id: product.id, brand: "Andrelon",
      product_type_id: product_types(:dishwashing_liquid).id)

    assert_equal [ "Andrelon", product_types(:dishwashing_liquid) ], [ product.reload.brand, product.product_type ]
    assert_not_includes ask_assistant("list_unclassified_products"), "Andrelon shampoo"
  end

  test "editing a product replaces the brand and type it already had, as the app does" do
    product = products(:ah_ribbelchips)

    answer = ask_assistant("update_product", product_id: product.id, name: "Lay's Naturel", brand: "Lay's",
      product_type_id: product_types(:dishwashing_liquid).id)

    assert_equal [ "Lay's Naturel", "Lay's", product_types(:dishwashing_liquid) ],
      [ product.reload.name, product.brand, product.product_type ]
    assert_includes answer, "Updated product #{product.id}"
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
