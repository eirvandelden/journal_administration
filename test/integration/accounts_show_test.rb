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

  test "show links a recent transaction to its show and edit page" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_select "a[href='#{transaction_path(transactions(:debit_grocery))}']"
    assert_select "a[href='#{edit_transaction_path(transactions(:debit_grocery))}']"
  end

  test "show paginates recent transactions to the next page" do
    oldest = Transaction.create!(
      amount: 5,
      booked_at: 1.day.from_now,
      interest_at: 1.day.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    20.times do |index|
      Transaction.create!(
        amount: 10 + index,
        booked_at: 2.days.from_now + index.minutes,
        interest_at: 2.days.from_now + index.minutes,
        debitor: accounts(:checking),
        creditor: accounts(:albert_heijn),
        category: categories(:supermarket)
      )
    end

    get account_path(accounts(:checking))

    assert_select "a[rel='next']"
    assert_not_includes response.body, transaction_path(oldest)

    get account_path(accounts(:checking), transactions_page: 2)

    assert_select "a[rel='prev']"
    assert_includes response.body, transaction_path(oldest)
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

  test "show renders a destroy button" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_select "form[action='#{account_path(accounts(:checking))}']"
  end

  test "edit renders a destroy button" do
    get edit_account_path(accounts(:checking))

    assert_response :success
    assert_select "form[action='#{account_path(accounts(:checking))}']"
  end

  test "destroy redirects to accounts index on success" do
    delete account_path(accounts(:jumbo))

    assert_redirected_to accounts_url
    assert_equal I18n.t("accounts.destroy.success"), flash[:notice]
  end

  test "destroy redirects back with alert when account has transactions" do
    delete account_path(accounts(:checking))

    assert_redirected_to account_path(accounts(:checking))
    assert_predicate flash[:alert], :present?
  end
end
