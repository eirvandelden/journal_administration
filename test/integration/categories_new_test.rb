require "test_helper"

class CategoriesNewTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
  end

  test "new renders category form" do
    sign_in_as(@member)

    get new_category_url

    assert_response :success
    assert_select "form"
    assert_select "select[name='category[direction]']"
  end
end
