require "test_helper"

class RecordFormsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  test "the new account form creates an account" do
    get new_account_path

    assert_select "form[action='#{accounts_path}'][method=post] [name^='account[']"
  end

  test "the new category form creates a category" do
    get new_category_path

    assert_select "form[action='#{categories_path}'][method=post] [name^='category[']"
  end

  test "the edit chattel form updates the chattel and uploads a warranty" do
    chattel = chattels(:one)

    get edit_chattel_path(chattel)

    assert_select "form[action='#{chattel_path(chattel)}'][enctype='multipart/form-data']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "input[type=file][name='chattel[warranty_document]']"
    end
  end

  test "the new product type form creates a product type" do
    get new_product_type_path

    assert_select "form[action='#{product_types_path}'][method=post] [name^='product_type[']"
  end

  test "the edit product form updates the product" do
    product = products(:ah_ribbelchips)

    get edit_product_path(product)

    assert_select "form[action='#{product_path(product)}']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "[name^='product[']"
    end
  end

  test "the new transaction form creates a transaction" do
    get new_transaction_path

    assert_select "form[action='#{transactions_path}'][method=post] [name^='transaction[']"
  end

  test "the edit form of a credit updates it as a credit and uploads a proof of purchase" do
    credit = transactions(:credit_salary)

    get edit_transaction_path(credit)

    assert_select "form[action='#{credit_path(credit)}'][enctype='multipart/form-data']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "input[type=file][name='credit[proof_of_purchase]']"
    end
  end
end
