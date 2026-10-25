# Helpers for choosing an appropriation
module AppropriationsHelper
  # Options for an appropriation select: this year's appropriations, one group per person,
  # plus the selected one from any year
  #: (?selected: Appropriation?) -> ActiveSupport::SafeBuffer
  def grouped_appropriation_options(selected: nil)
    grouped_options_for_select(appropriation_choices(selected), selected&.id)
  end

  private

  # This year's appropriations and the selected one as ["Purpose Year", id] pairs, keyed by the person's name
  #: (Appropriation?) -> Hash[String, Array[[String, Integer]]]
  def appropriation_choices(selected)
    Appropriation.of_year(Date.current.year).or(Appropriation.where(id: selected&.id)).per_person
      .transform_values { |appropriations| appropriations.map { |choice| [ choice.purpose_and_year, choice.id ] } }
  end
end
