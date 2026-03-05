require "test_helper"

class CategoriesShowTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "show renders recent transactions heading" do
    get category_path(categories(:supermarket))

    assert_response :success
    assert_select "h2", text: I18n.t("transactions.recent.heading")
  end

  test "show renders transactions for the category" do
    get category_path(categories(:supermarket))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
  end

  test "show for parent category renders transactions from child categories" do
    get category_path(categories(:groceries))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
    assert_includes response.body, transactions(:debit_bakery).note
  end

  test "edit renders recent transactions heading" do
    get edit_category_path(categories(:supermarket))

    assert_response :success
    assert_select "h2", text: I18n.t("transactions.recent.heading")
  end

  test "edit renders transactions for the category" do
    get edit_category_path(categories(:supermarket))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
  end

  test "edit for parent category renders transactions from child categories" do
    get edit_category_path(categories(:groceries))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
    assert_includes response.body, transactions(:debit_bakery).note
  end
end
