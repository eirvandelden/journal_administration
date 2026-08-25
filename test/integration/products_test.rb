require "test_helper"

class ProductsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:member)
  end

  test "the products page lists what we buy with brand and type" do
    get products_path

    assert_response :success
    assert_select "tbody td", text: products(:ah_ribbelchips).name
    assert_select "tbody td", text: products(:ah_ribbelchips).brand
    assert_select "tbody td", text: product_types(:naturel_chips).name
  end

  test "the products page marks what still needs classifying" do
    get products_path

    assert_response :success
    assert_select "tbody tr", text: /#{Regexp.escape(I18n.t("products.index.unclassified", locale: :en))}/
  end

  test "classifying a product records its brand and type" do
    shampoo = ProductType.create!(name: "Shampoo", category: categories(:household))
    product = products(:andrelon_shampoo)

    patch product_path(product), params: { product: { brand: "Andrélon", product_type_id: shampoo.id } }

    assert_redirected_to products_path
    assert_not product.reload.unclassified?
    assert_equal shampoo, product.product_type
  end

  test "the brand field offers the brands already in use" do
    get edit_product_path(products(:andrelon_shampoo))

    assert_response :success
    assert_select "datalist option[value=?]", products(:lays_ribbelchips).brand
  end

  test "a product cannot lose its name" do
    product = products(:ah_ribbelchips)

    patch product_path(product), params: { product: { name: "" } }

    assert_response :success
    assert_select "#error_explanation li"
    assert_equal "AH Naturel Ribbelchips", product.reload.name
  end
end
