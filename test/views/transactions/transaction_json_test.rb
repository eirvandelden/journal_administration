require "test_helper"

class TransactionJsonTest < ActionView::TestCase
  test "renders the amount in euros as before" do
    transaction = transactions(:debit_bakery)
    # The partial also reads columns that no longer exist; this test only checks the amount.
    transaction.define_singleton_method(:from_account_id) { nil }
    transaction.define_singleton_method(:to_account_id) { nil }

    json = JSON.parse(render(partial: "transactions/transaction", formats: [ :json ], locals: { transaction: }))

    assert_equal "12.5", json["amount"]
  end
end
