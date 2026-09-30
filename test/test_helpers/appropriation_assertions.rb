# Reads the appropriations page the way a person does: one row per appropriation,
# its purpose and recipient followed by what was appropriated, charged and left.
module AppropriationAssertions
  def assert_appropriation_row(purpose, recipient, appropriated, charged, balance)
    cells = [ purpose, recipient, currency(appropriated), currency(charged), currency(balance) ]

    assert_select "tbody tr", text: /#{cells.map { |cell| Regexp.escape(cell) }.join(".*")}/m
  end

  def currency(amount) = ApplicationController.helpers.number_to_currency(amount)
end
