require "test_helper"

class AccountsShowTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "show renders recent transactions heading" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_select "h2", text: I18n.t("transactions.recent.heading")
  end

  test "show does not render recognition patterns for a family account" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_select "h2", text: I18n.t("accounts.show.aliases"), count: 0
  end

  test "show renders recognition patterns for an external account" do
    get account_path(accounts(:albert_heijn))

    assert_response :success
    assert_select "h2", text: I18n.t("accounts.show.aliases")
  end

  test "show renders a transaction where account is debitor" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
  end

  test "edit renders recent transactions heading" do
    get edit_account_path(accounts(:checking))

    assert_response :success
    assert_select "h2", text: I18n.t("transactions.recent.heading")
  end

  test "edit renders a transaction where account is creditor" do
    get edit_account_path(accounts(:checking))

    assert_response :success
    assert_includes response.body, transactions(:credit_salary).note
  end
end
