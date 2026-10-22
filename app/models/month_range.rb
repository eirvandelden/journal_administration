# A period of whole calendar months, from 00:00 on the first day of its first month to
# the end of the last day of its last month.
#
# This is the only span the dashboard page builds. It cannot be built from exact days,
# so a monthly budget over it always counts whole months.
class MonthRange < DateRange
  # The quick filters the dashboard offers; each one is a whole-month period.
  QUICK_FILTERS = %w[current_month last_month three_months current_year last_year].freeze

  MONTH_FORMAT = /\A\d{4}-(0[1-9]|1[0-2])\z/

  private_class_method :new, :from_dates, :from_filter

  # The period a dashboard visitor chose: a known quick filter wins, then the two months,
  # else the current month.
  #
  # @return [MonthRange]
  def self.from_selection(filter:, from_month:, to_month:, today: Date.current)
    quick_filter(filter, today) || picked(from_month, to_month) || spanning(today, today)
  end

  # The one builder: the first day of the first month through the last day of the last month.
  #
  # @return [MonthRange]
  def self.spanning(first_month, last_month)
    new(first_month.beginning_of_month.beginning_of_day, last_month.end_of_month.end_of_day)
  end

  # @return [MonthRange, nil]
  def self.quick_filter(filter, today)
    case filter
    when "current_month" then spanning(today, today)
    when "last_month" then spanning(today.last_month, today.last_month)
    when "three_months" then spanning(today.months_ago(3), today.last_month)
    when "current_year" then spanning(today.beginning_of_year, today)
    when "last_year" then spanning(today.last_year.beginning_of_year, today.last_year.end_of_year)
    end
  end

  # @return [MonthRange, nil]
  def self.picked(from_month, to_month)
    first_month = month(from_month)
    last_month = month(to_month)
    return unless first_month && last_month && first_month <= last_month

    spanning(first_month, last_month)
  end

  # @return [Date, nil]
  def self.month(value)
    return unless value.to_s.match?(MONTH_FORMAT)

    Date.strptime(value, "%Y-%m")
  end

  private_class_method :quick_filter, :picked, :month

  # The number of calendar months in the period.
  #
  # @return [Integer]
  def month_count
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month) + 1
  end
end
