require "test_helper"

class Assistant::ClassifyProductTest < ActiveSupport::TestCase
  test "fills in a brand and type and says what it set" do
    product = products(:andrelon_shampoo)

    response = classify(product.id, brand: "Andrelon", product_type_id: product_types(:dishwashing_liquid).id)

    assert_includes text(response), "Andrelon, Dishwashing liquid."
    assert_not_includes text(response), "Kept"
  end

  test "says what it kept because it was already present" do
    response = classify(products(:ah_ribbelchips).id, brand: "Other",
product_type_id: product_types(:dishwashing_liquid).id)

    assert_includes text(response), "Kept the brand AH and the type Naturel chips"
  end

  test "takes either field alone" do
    assert_not classify(products(:andrelon_shampoo).id, brand: "Andrelon").error?
  end

  test "refuses an unknown product" do
    assert_predicate classify(0, brand: "AH"), :error?
  end

  test "refuses an unknown product type" do
    assert_predicate classify(products(:andrelon_shampoo).id, product_type_id: 0), :error?
  end

  private

  def classify(product_id, **fields)
    Assistant::ClassifyProduct.call(product_id: product_id, server_context: nil, **fields)
  end

  def text(response) = response.content.first[:text]
end
