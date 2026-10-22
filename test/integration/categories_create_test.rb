require "test_helper"

class CategoriesCreateTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "creating a category without a parent stores no parent" do
    post categories_path, params: { category: { name: "Kinderen", direction: "debit", parent_category_id: "" } }

    assert_nil Category.find_by!(name: "Kinderen").parent_category_id
  end

  test "a category created without a parent is offered as a parent" do
    post categories_path, params: { category: { name: "Kinderen", direction: "debit", parent_category_id: "" } }
    get new_category_path

    assert_select "select#category_parent_category_id option", text: "Kinderen"
  end

  test "updating a category with a blank parent clears the parent" do
    category = categories(:groceries)
    patch category_path(category), params: { category: { parent_category_id: "" } }

    assert_nil category.reload.parent_category_id
  end
end
