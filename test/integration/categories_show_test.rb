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

  test "show renders split amount and split category for split transactions" do
    get category_path(categories(:bakery))

    assert_response :success
    assert_match split_row_pattern_for(amount: 10, category: categories(:bakery), note: transactions(:debit_grocery).note), response.body
  end

  test "show includes the remainder amount for the original category" do
    transactions(:debit_grocery).ensure_remainder_split

    get category_path(categories(:supermarket))

    assert_response :success
    assert_match split_row_pattern_for(amount: 40, category: categories(:supermarket), note: transactions(:debit_grocery).note), response.body
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

  test "new renders successfully" do
    get new_category_path

    assert_response :success
  end

  test "new parent_category select contains only root categories" do
    get new_category_path

    assert_select "select[name='category[parent_category_id]']" do
      assert_select "option", text: categories(:groceries).name
      assert_select "option", text: categories(:housing).name
      assert_select "option", text: categories(:income).name
      assert_select "option", text: categories(:transfer).name
    end
  end

  test "new parent_category select does not contain child categories" do
    get new_category_path

    assert_select "select[name='category[parent_category_id]']" do
      assert_select "option", text: categories(:supermarket).name, count: 0
      assert_select "option", text: categories(:bakery).name, count: 0
      assert_select "option", text: categories(:rent).name, count: 0
      assert_select "option", text: categories(:salary).name, count: 0
    end
  end

  private

  def split_row_pattern_for(amount:, category:, note:)
    formatted_amount = Regexp.escape(ApplicationController.helpers.number_to_currency(amount))
    formatted_category = Regexp.escape(category.name)
    formatted_note = Regexp.escape(note)

    %r{<td>#{formatted_amount}</td>\s*<td>.*?</td>\s*<td>#{formatted_category}</td>\s*<td>#{formatted_note}</td>}m
  end
end
