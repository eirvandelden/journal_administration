# Reads the appropriations page the way a person does: one section per person, one row per appropriation
# in it, its purpose followed by what was appropriated, a bar of what is charged and what is left.
module AppropriationAssertions
  def assert_appropriation_row(purpose, recipient, appropriated, charged, balance)
    cells = [ purpose, currency(appropriated), currency(balance) ]
    section = css_select("tbody").find { |body| body.at_css("th")&.text&.strip == recipient }

    assert section, "a section for #{recipient}"
    assert section.css("tr").any? { |row| row_matches?(row, cells, appropriated, charged) },
      "a row #{cells.join(', ')} charged #{currency(charged)} in the section for #{recipient}"
  end

  # Reads the show page's charged and balance values next to their labels.
  def assert_appropriation_figures(charged, balance)
    { I18n.t("appropriations.show.charged") => charged, I18n.t("appropriations.show.balance") => balance }
      .each do |label, amount|
        term = css_select("dt").find { |candidate| candidate.text.strip == label }

        assert_equal currency(amount), term.next_element.text.strip, "#{label} on the show page"
      end
  end

  def row_matches?(row, cells, appropriated, charged)
    bar = row.at_css("progress[max='#{appropriated}']")

    row.text.match?(/#{cells.map { |cell| Regexp.escape(cell) }.join(".*")}/m) &&
      bar&.[]("aria-label")&.include?(currency(charged))
  end

  def currency(amount) = ApplicationController.helpers.cents_to_currency(amount)
end
