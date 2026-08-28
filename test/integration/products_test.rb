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
  test "a product page shows what each purchase cost" do
    get product_path(products(:lays_ribbelchips))

    assert_response :success
    currency = ApplicationController.helpers.method(:number_to_currency)

    assert_select "tbody td", text: currency.call(BigDecimal("2.19"))
    assert_select "tbody td", text: currency.call(BigDecimal("0.70"))
    assert_select "tbody td", text: currency.call(BigDecimal("1.49"))
    assert_select "tbody td", text: /#{Regexp.escape(currency.call(BigDecimal("4.97")))}/
  end

  test "a product page says when we never bought it" do
    get product_path(products(:andrelon_shampoo))

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("products.show.never_bought", locale: :en))}/
    assert_select "tbody td", count: 0
  end
  test "a product bought more than once is charted" do
    buy_again(products(:lays_ribbelchips), shelf: 2.29, paid: 2.29)

    get product_path(products(:lays_ribbelchips))

    assert_response :success
    assert_select "svg polyline", count: 2
  end

  test "a product bought once shows the table without a chart" do
    get product_path(products(:lays_ribbelchips))

    assert_response :success
    assert_select "svg", count: 0
    assert_select "#purchases-table"
  end

  test "the chart says what it shows" do
    buy_again(products(:lays_ribbelchips), shelf: 2.29, paid: 2.29)

    get product_path(products(:lays_ribbelchips))

    assert_response :success
    assert_select "svg title"
    assert_select "figcaption", text: /#{Regexp.escape(I18n.t("products.price_chart.shelf_series", locale: :en))}/
    assert_select "figcaption", text: /#{Regexp.escape(I18n.t("products.price_chart.paid_series", locale: :en))}/
  end

  private

  def buy_again(product, shelf:, paid:)
    receipt = Receipt.create!(shop: accounts(:albert_heijn), issued_on: 2.months.ago.to_date, total_amount: shelf)
    receipt.lines.create!(product: product, quantity: 1, pack_amount: 300, pack_unit: :gram,
                          full_amount: shelf, discount_amount: shelf - paid, paid_amount: paid)
  end
end
