require "test_helper"

class Assistant::CreateProductTypeTest < ActiveSupport::TestCase
  test "creates a type under the category" do
    response = create("Komkommer", categories(:household_groceries))

    assert_not response.error?
    assert_equal categories(:household_groceries), ProductType.find_by!(name: "Komkommer").category
  end

  test "finds a type by name whatever its case and keeps its category" do
    assert_no_difference "ProductType.count" do
      response = create("naturel CHIPS", categories(:household_groceries))

      assert_includes response.content.first[:text], "already exists and books to Groceries"
    end
    assert_equal categories(:groceries), product_types(:naturel_chips).reload.category
  end

  test "refuses the Transfer category" do
    assert_predicate create("Overboeking", categories(:transfer)), :error?
  end

  test "refuses an unknown category" do
    response = Assistant::CreateProductType.call(name: "X", category_id: 0, server_context: nil)

    assert_predicate response, :error?
  end

  test "reports validation errors" do
    response = create(" ", categories(:groceries))

    assert_predicate response, :error?
    assert_includes response.content.first[:text], "Name"
  end

  private

  def create(name, category)
    Assistant::CreateProductType.call(name: name, category_id: category.id, server_context: nil)
  end
end
