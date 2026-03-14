# Provides full-text search across declared model columns
#
# Call `searchable_on` with column names to declare which columns are searched.
# Adds a `.search(query)` class scope that uses SQLite LIKE across all columns.
module Searchable
  extend ActiveSupport::Concern

  class_methods do
    # Declares which columns are searched and defines the `.search` scope
    #
    # @param columns [Array<Symbol>] Column names to include in search
    # @return [void]
    def searchable_on(*columns)
      @searchable_columns = columns

      scope :search, ->(query) {
        return none if query.blank?

        sanitized = "%#{sanitize_sql_like(query.to_s.strip)}%"
        conditions = columns.map { |col| "#{col} LIKE ?" }
        where(conditions.join(" OR "), *conditions.map { sanitized }).limit(10)
      }
    end

    # Returns the declared searchable column names
    #
    # @return [Array<Symbol>]
    def searchable_columns
      @searchable_columns || []
    end
  end
end
