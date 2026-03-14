require "test_helper"

class PaginationNavigationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  test "accounts pagination shows correct links on first and last page" do
    create_accounts(51)

    get accounts_path
    assert_response :success
    assert_select "nav.pagination a[rel='next'][href*='own_page=2']", 2
    assert_select "nav.pagination a[rel='prev']", 0

    get accounts_path, params: { own_page: 2 }
    assert_response :success
    assert_select "nav.pagination a[rel='prev'][href*='own_page=1']", 2
    assert_select "nav.pagination a[rel='next']", 0
  end

  test "transactions pagination keeps filter params and does not show next on overflow pages" do
    create_uncategorized_transactions(21)

    get transactions_path, params: { filter: "no_category" }
    assert_response :success
    assert_select "nav.pagination a[rel='next'][href*='filter=no_category'][href*='page=2']", 2
    assert_select "nav.pagination a[rel='prev']", 0

    get transactions_path, params: { filter: "no_category", page: 999 }
    assert_response :success
    assert_select "nav.pagination a[rel='prev'][href*='filter=no_category'][href*='page=998']", 2
    assert_select "nav.pagination a[rel='next']", 0
  end

  test "transactions index renders when transaction interest_at is nil" do
    transaction = Transaction.new(
      booked_at: Time.current,
      interest_at: nil,
      note: "Nil interest date transaction"
    )
    transaction.mutations.build(account: accounts(:checking), amount: -10)
    transaction.mutations.build(account: accounts(:unknown), amount: 10)
    transaction.save!

    get transactions_path

    assert_response :success
    assert_select "table.transactions"
  end

  test "todo pagination is clamped and hides next on the last page" do
    create_uncategorized_transactions(21)

    get todo_path
    assert_response :success
    assert_select "nav.pagination a[rel='next'][href*='page=2']", 2
    assert_select "nav.pagination a[rel='prev']", 0

    get todo_path, params: { page: 999 }
    assert_response :success
    assert_select "nav.pagination a[rel='prev'][href*='page=1']", 2
    assert_select "nav.pagination a[rel='next']", 0
  end

  private
    def create_accounts(count)
      count.times do |index|
        Account.create!(
          account_number: format("NL99TEST%010d", index),
          name: "Pagination Account #{index}",
          owner: :samen
        )
      end
    end

    def create_uncategorized_transactions(count)
      outgoing_account = accounts(:checking)
      incoming_account = accounts(:unknown)

      count.times do |index|
        create_uncategorized_transaction(index, outgoing_account:, incoming_account:)
      end
    end

    def create_uncategorized_transaction(index, outgoing_account:, incoming_account:)
      transaction = Transaction.new(
        booked_at: index.minutes.ago,
        interest_at: index.minutes.ago,
        note: "Pagination transaction #{index}"
      )
      amount = index + 1
      transaction.mutations.build(account: outgoing_account, amount: -amount)
      transaction.mutations.build(account: incoming_account, amount: amount)
      transaction.save!
    end
end
