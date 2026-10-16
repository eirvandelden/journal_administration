require "test_helper"

class RecordFormsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  test "the new account form posts account fields to the accounts path" do
    get new_account_path

    assert_select "form[action='#{accounts_path}'][method=post] [name^='account[']"
  end

  test "the new category form posts category fields to the categories path" do
    get new_category_path

    assert_select "form[action='#{categories_path}'][method=post] [name^='category[']"
  end

  test "the edit chattel form patches the chattel with a warranty upload field" do
    chattel = chattels(:one)

    get edit_chattel_path(chattel)

    assert_select "form[action='#{chattel_path(chattel)}'][enctype='multipart/form-data']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "input[type=file][name='chattel[warranty_document]']"
    end
  end

  test "the new product type form posts product type fields to the product types path" do
    get new_product_type_path

    assert_select "form[action='#{product_types_path}'][method=post] [name^='product_type[']"
  end

  test "the edit product form patches the product" do
    product = products(:ah_ribbelchips)

    get edit_product_path(product)

    assert_select "form[action='#{product_path(product)}']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "[name^='product[']"
    end
  end

  test "the new transaction form posts transaction fields to the transactions path" do
    get new_transaction_path

    assert_select "form[action='#{transactions_path}'][method=post] [name^='transaction[']"
  end

  test "the edit form of a credit patches it as a credit with a proof of purchase field" do
    credit = transactions(:credit_salary)

    get edit_transaction_path(credit)

    assert_select "form[action='#{credit_path(credit)}'][enctype='multipart/form-data']" do
      assert_select "input[name=_method][value=patch]"
      assert_select "input[type=file][name='credit[proof_of_purchase]']"
    end
  end

  test "the edit page of a credit links back to the credit's own page" do
    credit = transactions(:credit_salary)

    get edit_transaction_path(credit)

    assert_select "a[href='#{credit_path(credit)}']"
  end
end
