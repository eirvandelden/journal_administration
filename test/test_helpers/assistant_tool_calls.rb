# Calls an assistant tool class directly and reads what it answered
module AssistantToolCalls
  private

  def said(response) = response.content.first[:text]

  def refused_response?(response) = response.error?

  def unsplit_debit(amount: 5000)
    Transaction.create!(debitor: accounts(:checking), creditor: accounts(:jumbo), amount: amount,
      booked_at: Time.zone.local(2026, 10, 20, 12), interest_at: Time.zone.local(2026, 10, 20, 12))
  end

  def line(name, quantity: 1, full_amount: 1.5, discount_amount: 0)
    { name:, quantity:, full_amount:, discount_amount: }
  end
end
