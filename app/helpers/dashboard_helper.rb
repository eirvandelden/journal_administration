module DashboardHelper
  # Option tags grouped per year, each month labelled in the current locale and valued YYYY-MM
  #
  # @param months [Array<Date>] Months to offer, in display order
  # @param selected [Date] The month to mark as selected
  # @return [ActiveSupport::SafeBuffer]
  def month_options(months, selected:)
    groups = months.group_by(&:year).map do |year, year_months|
      tag.optgroup(label: year) { options_for_select(month_choices(year_months), selected.strftime("%Y-%m")) }
    end

    safe_join(groups)
  end

  private

  def month_choices(months)
    months.map { |month| [ l(month, format: :month_and_year), month.strftime("%Y-%m") ] }
  end
end
