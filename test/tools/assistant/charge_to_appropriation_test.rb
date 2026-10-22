require "test_helper"

class Assistant::ChargeToAppropriationTest < ActiveSupport::TestCase
  test "reports amounts in euros as before" do
    transaction = transactions(:debit_bakery)

    response = Assistant::ChargeToAppropriation.call(
      appropriation_id: appropriations(:birthday_etienne).id, transaction_id: transaction.id, server_context: nil
    )

    assert_match(/\ACharged 12\.50 to /, response.content.first[:text])
  end

  test "lists the parts of a split payment in euros" do
    response = Assistant::ChargeToAppropriation.call(
      appropriation_id: appropriations(:birthday_etienne).id,
      transaction_id: transactions(:debit_grocery).id, server_context: nil
    )

    text = response.content.first[:text]

    assert_includes text, "#{transaction_splits(:split_grocery_supermarket).id}: 30.00 "
    assert_includes text, "#{transaction_splits(:split_grocery_bakery).id}: 10.00 "
  end
end
