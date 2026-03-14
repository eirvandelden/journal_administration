require "test_helper"

class CategoriesIndexTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "index renders one section per parent category" do
    get categories_path

    assert_response :success
    assert_select "h2", text: I18n.t("categories.index.root_categories")
    assert_select "h2", text: categories(:groceries).name
    assert_select "h2", text: categories(:housing).name
    assert_select "h2", text: categories(:income).name
  end

  test "index renders root categories under the root section" do
    get categories_path

    assert_response :success
    assert_select "section" do
      assert_select "h2", text: I18n.t("categories.index.root_categories")
      assert_select "td", text: categories(:groceries).name
      assert_select "td", text: categories(:housing).name
      assert_select "td", text: categories(:income).name
      assert_select "td", text: categories(:transfer).name
    end
  end

  test "index renders child categories under their parent section" do
    get categories_path

    assert_response :success
    assert_select "section", count: 5
    assert_select "td", text: categories(:bakery).name
    assert_select "td", text: categories(:supermarket).name
    assert_select "td", text: categories(:rent).name
    assert_select "td", text: categories(:salary).name
  end

  test "index does not show parent column per row" do
    get categories_path

    assert_response :success
    assert_select "th", text: I18n.t("categories.index.root_categories"), count: 0
  end
end
