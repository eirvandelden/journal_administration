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
      debitor = accounts(:checking)
      creditor = accounts(:unknown)

      count.times do |index|
        Transaction.create!(uncategorized_transaction_attributes(index, debitor:, creditor:))
      end
    end

    def uncategorized_transaction_attributes(index, debitor:, creditor:)
      {
        amount: index + 1,
        booked_at: index.minutes.ago,
        interest_at: index.minutes.ago,
        debitor: debitor,
        creditor: creditor,
        note: "Pagination transaction #{index}"
      }
    end
end
