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

    assert_response :unprocessable_entity
    assert_select "#error_explanation li"
  end

  test "two product types cannot share a name" do
    assert_no_difference "ProductType.count" do
      post product_types_path,
        params: { product_type: { name: product_types(:naturel_chips).name, category_id: categories(:groceries).id } }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation li"
  end
  test "a product type page compares the brands we buy it from" do
    get product_type_path(product_types(:naturel_chips))

    assert_response :success
    assert_select "tbody td", text: products(:ah_ribbelchips).brand
    assert_select "tbody td", text: products(:lays_ribbelchips).brand
  end

  test "a product type page totals each month, bonus count included" do
    get product_type_path(product_types(:naturel_chips))

    assert_response :success
    currency = ApplicationController.helpers.method(:number_to_currency)

    assert_select "#monthly-totals-table tbody td", text: currency.call(BigDecimal("2.98"))
    assert_select "#monthly-totals-table tbody td", text: "1"
  end

  test "a product type page says when nothing was ever bought under it" do
    shampoo = ProductType.create!(name: "Shampoo", category: categories(:household))

    get product_type_path(shampoo)

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("product_types.show.never_bought", locale: :en))}/
  end
end
