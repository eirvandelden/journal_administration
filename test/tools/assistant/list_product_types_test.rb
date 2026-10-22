require "test_helper"

class Assistant::ListProductTypesTest < ActiveSupport::TestCase
  test "lists each type with the category it books to, then the brands in use" do
    text = Assistant::ListProductTypes.call(server_context: nil).content.first[:text]

    assert_includes text, "#{product_types(:naturel_chips).id}: Naturel chips - Groceries"
    assert_includes text, "Brands in use: "
    assert_includes text, "AH"
  end
end
