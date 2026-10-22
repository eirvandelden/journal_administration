require "test_helper"

class TransactionsImportsTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "new renders the upload form" do
    get new_transactions_import_path

    assert_response :success
    assert_select "form[action='#{transactions_imports_path}'][method='post']"
    assert_select "input[type='file'][name='csv']"
  end

  test "create without a file redirects back to the upload page" do
    post transactions_imports_path

    assert_redirected_to new_transactions_import_path
    follow_redirect!

    assert_select "form[action='#{transactions_imports_path}'][method='post']"
  end

  test "new has a title bar h1 and an action row with Annuleren" do
    get new_transactions_import_path

    assert_select "main > header > h1", count: 1
    assert_select "form > footer a[role=button][href=?]", transactions_path
  end
end
