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

  test "show lists each recognition pattern of an external account" do
    get account_path(accounts(:albert_heijn))

    assert_select "li", text: /#{account_aliases(:albert_heijn_ah_to_go).pattern}/
  end

  test "show renders a transaction where account is debitor" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
  end

  test "show links a recent transaction to its show page" do
    get account_path(accounts(:checking))

    assert_response :success
    assert_select "a[href='#{polymorphic_path(transactions(:debit_grocery))}']"
    assert_select "a[href='#{edit_transaction_path(transactions(:debit_grocery))}']", count: 0
  end

  test "show lists the interest date column" do
    get account_path(accounts(:checking))

    assert_select "table.transactions thead th", count: 8
    assert_select "table.transactions thead th", text: I18n.t("transactions.table.interest_date")
    interest_at = transactions(:debit_grocery).interest_at

    assert_select "table.transactions time[datetime='#{interest_at.to_date.iso8601}']"
  end

  test "show renders split sub-rows with amount category and note" do
    get account_path(accounts(:checking))

    assert_select "tr.split-row", count: 2
    assert_select "tr.split-row", text: /Supermarket items/
    assert_select "tr.split-row", text: /Bakery items/
    assert_select "tr.split-row data[value='3000']"
    assert_select "tr.split-row data[value='1000']"
  end

  test "show links the amount to the transaction which offers edit" do
    get account_path(accounts(:checking))
    href = css_select("table.transactions a[href='#{polymorphic_path(transactions(:debit_grocery))}']").first["href"]

    get href

    assert_response :success
    assert_select "a[href='#{edit_transaction_path(transactions(:debit_grocery))}']"
  end

  test "show renders an empty table for an account without transactions" do
    get account_path(accounts(:jumbo))

    assert_response :success
    assert_select "table.transactions tbody tr", count: 0
  end

  test "show renders no filters form" do
    get account_path(accounts(:checking))

    assert_select "form[action='#{transactions_path}'][method='get']", count: 0
  end

  test "show runs the same number of queries for 21 and 41 transactions" do
    create_checking_transactions(21)
    small = count_queries { get account_path(accounts(:checking)) }
    create_checking_transactions(20)
    large = count_queries { get account_path(accounts(:checking)) }

    assert_equal small, large
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
    assert_not_includes response.body, "/#{oldest.id}"

    get css_select("a[rel='next']").first["href"]

    assert_select "a[rel='prev']"
    assert_includes response.body, "/#{oldest.id}"
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

  test "edit renders a destroy button" do
    get edit_account_path(accounts(:checking))

    assert_response :success
    assert_select "form##{dom_id(accounts(:checking), :delete)}[action='#{account_path(accounts(:checking))}']"
  end

  test "destroy redirects to accounts index on success" do
    delete account_path(accounts(:jumbo))

    assert_redirected_to accounts_url
    assert_equal I18n.t("accounts.destroy.success"), flash[:notice]
  end

  test "show offers to mark an external account as a shared provider" do
    get account_path(accounts(:adyen))

    assert_select "form[action=?]", account_payment_provider_path(accounts(:adyen)) do
      assert_select "button", text: I18n.t("accounts.show.mark_payment_provider")
    end
    assert_select "form[action=?]", account_merchant_reassignment_path(accounts(:adyen)), count: 0
  end

  test "show offers the move only for a provider" do
    accounts(:adyen).update!(payment_provider: true)

    get account_path(accounts(:adyen))

    assert_select "form[action=?]", account_merchant_reassignment_path(accounts(:adyen)) do
      assert_select "button", text: I18n.t("accounts.show.move_to_merchants")
    end
    assert_select "button", text: I18n.t("accounts.show.unmark_payment_provider")
  end

  test "show displays the current managed owner name" do
    groups(:samen).update!(name: "Delden Household")

    get account_path(accounts(:checking))

    assert_select "article dd", text: /Delden Household/
  end

  test "show page has no delete button" do
    get account_path(accounts(:checking))

    assert_select "button.button-danger", count: 0
    assert_select "form[method=post] input[name=_method][value=delete]", count: 0
  end

  test "show page lists the fields as a description list" do
    get account_path(accounts(:checking))

    assert_select "main dl dt", minimum: 3
  end

  private

  def create_checking_transactions(count)
    count.times do |index|
      Transaction.create!(
        amount: 10 + index,
        booked_at: 2.days.from_now + index.minutes,
        interest_at: 2.days.from_now + index.minutes,
        debitor: accounts(:checking),
        creditor: accounts(:albert_heijn),
        category: categories(:supermarket)
      )
    end
  end

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
