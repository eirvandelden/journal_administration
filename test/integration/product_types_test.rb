require "test_helper"

class ProductTypesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:member)
  end

  test "the product types page lists each type with the category it is booked to" do
    get product_types_path

    assert_response :success
    assert_select "tbody td", text: product_types(:naturel_chips).name
    assert_select "tbody td", text: categories(:groceries).name
  end

  test "a product type can be created for a category" do
    assert_difference "ProductType.count", 1 do
      post product_types_path, params: { product_type: { name: "Shampoo", category_id: categories(:household).id } }
    end

    assert_redirected_to product_types_path
    assert_equal categories(:household), ProductType.find_by(name: "Shampoo").category
  end

  test "a product type must say which category its groceries are booked to" do
    assert_no_difference "ProductType.count" do
      post product_types_path, params: { product_type: { name: "Shampoo" } }
    end

    assert_response :success
    assert_select "#error_explanation li"
  end

  test "two product types cannot share a name" do
    assert_no_difference "ProductType.count" do
      post product_types_path,
        params: { product_type: { name: product_types(:naturel_chips).name, category_id: categories(:groceries).id } }
    end

    assert_response :success
    assert_select "#error_explanation li"
  end
end
