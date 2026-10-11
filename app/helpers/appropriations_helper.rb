# Helpers for choosing an appropriation
module AppropriationsHelper
  # Options for an appropriation select, grouped by budget year with the newest year first
  #
  # @param selected [Appropriation, nil] the appropriation to mark as chosen
  # @return [ActiveSupport::SafeBuffer]
  def grouped_appropriation_options(selected: nil)
    grouped_options_for_select(appropriations_per_year, selected&.id)
  end

  private

  # Every appropriation as [label, id] pairs, keyed by its budget year
  # @return [Hash{String => Array<Array(String, Integer)>}]
  def appropriations_per_year
    Appropriation.includes(:person).order(budget_year: :desc, purpose: :asc).to_a
      .group_by { |appropriation| appropriation.budget_year.to_s }
      .transform_values do |appropriations|
        appropriations.sort_by { |appropriation| appropriation.recipient_name.downcase }
          .map { |choice| [ choice.to_s, choice.id ] }
      end
  end
end
