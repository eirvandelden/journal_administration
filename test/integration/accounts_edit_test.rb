require "test_helper"

class AccountsEditTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:albert_heijn)
  end

  test "edit form ends in an action row of Verwijderen…, Annuleren and Opslaan" do
    get edit_account_path(@account)

    assert_select "form[action='#{account_path(@account)}'] > footer" do
      assert_select "> *:nth-child(1)[form='#{dom_id(@account, :delete)}']", text: I18n.t("common.delete_ellipsis")
      assert_select "> *:nth-child(2)", text: I18n.t("common.cancel")
      assert_select "> *:nth-child(3)[type=submit]"
    end
    assert_select "form##{dom_id(@account, :delete)}[action='#{account_path(@account)}']"
  end

  test "new form ends in an action row of Annuleren and Opslaan" do
    get new_account_path

    assert_select "form > footer > *", count: 2
    assert_select "form > footer button[form]", count: 0
    assert_select "form > footer input[type=submit]", count: 1
  end

  test "Annuleren on the edit page links to the account" do
    get edit_account_path(@account)

    assert_select "form > footer a[role=button][href='#{account_path(@account)}']", text: I18n.t("common.cancel")
  end

  test "Annuleren on the new page links to the accounts index" do
    get new_account_path

    assert_select "form > footer a[role=button][href='#{accounts_path}']", text: I18n.t("common.cancel")
  end

  test "a rejected save shows the errors in an alert above the fields" do
    other_number = accounts(:checking).numbers.first

    patch account_path(@account),
      params: { account: { account_numbers_attributes: { "0" => { number: other_number } } } }

    assert_response :unprocessable_entity
    assert_select "form > aside[role=alert] li"
    assert_select "#error_explanation", count: 0
  end

  test "a refused delete returns to the edit page with the reason" do
    account = accounts(:checking)

    delete account_path(account)

    assert_redirected_to edit_account_path(account)
    assert_predicate flash[:alert], :present?
  end

  test "the edit page has a title bar with one h1" do
    get edit_account_path(@account)

    assert_select "main > header > h1", count: 1
  end
end
