# Builds household payments in a test, so appropriation tests control the direction of each one
# without adding fixtures that every dashboard and list test would count.
module AppropriationPayments
  def credit(amount, note:, on: Time.zone.local(2026, 10, 20, 12))
    payment(amount, note:, on:, creditor: accounts(:savings), debitor: accounts(:unknown))
  end

  def debit(amount, note:, on: Time.zone.local(2026, 10, 20, 12))
    payment(amount, note:, on:, creditor: accounts(:unknown), debitor: accounts(:savings))
  end

  private

  def payment(amount, note:, on:, creditor:, debitor:)
    Transaction.create!(
      creditor:, debitor:, category: categories(:gifts), amount:, note:, booked_at: on, interest_at: on
    )
  end
end
