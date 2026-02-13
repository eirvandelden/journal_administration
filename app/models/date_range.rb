# Represents a date range for filtering transactions
#
# Provides convenient factory methods to create common date ranges like last month,
# year-to-date, etc. Used primarily by Dashboard for temporal analysis.
class DateRange
  FILTERS = %w[last_month three_months year_to_date last_year current_month].freeze

  # @return [Time] The start date of the range (inclusive)
  attr_reader :start_date

  # @return [Time] The end date of the range (inclusive)
  attr_reader :end_date

  # Creates a DateRange from a predefined filter
  #
  # @param filter [String, nil] The filter name (last_month, three_months, year_to_date, last_year, current_month)
  #                             Defaults to current_month if not recognized
  # @return [DateRange] A new DateRange instance with appropriate start and end dates
  def self.from_filter(filter)
    case filter
    when "last_month"
      new(Time.current.last_month.beginning_of_month,
          Time.current.last_month.end_of_month)
    when "three_months"
      new(Time.current.months_ago(3).beginning_of_month,
          Time.current.last_month.end_of_month)
    when "year_to_date"
      new(Time.current.beginning_of_year,
          Time.current.end_of_year)
    when "last_year"
      new(Time.current.last_year.beginning_of_year,
          Time.current.last_year.end_of_year)
    else
      new(Time.current.beginning_of_month,
          Time.current.end_of_month)
    end
  end

  # Initializes a new DateRange
  #
  # @param start_date [Time] The start date (inclusive)
  # @param end_date [Time] The end date (inclusive)
  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  # Returns the range as a Ruby Range object suitable for database queries
  #
  # @return [Range<Time>] The date range
  def to_range
    start_date..end_date
  end
end
