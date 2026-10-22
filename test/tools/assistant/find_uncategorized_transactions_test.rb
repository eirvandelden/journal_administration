require "test_helper"

class Assistant::FindUncategorizedTransactionsTest < ActiveSupport::TestCase
  test "reports amounts in euros as before" do
    transaction = transactions(:uncategorized)
    transaction.update!(amount: 1250)

    text = Assistant::FindUncategorizedTransactions.call(server_context: nil).content.first[:text]

    assert_includes text, "#{transaction.id}: #{transaction.booked_at.to_date} 12.5 from"
    assert_not_includes text, "1250"
  end
end
