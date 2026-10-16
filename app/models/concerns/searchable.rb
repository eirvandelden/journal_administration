# Provides full-text search across declared model columns
#
# Call `searchable_on` with column names to declare which columns are searched.
# Adds a `.search(query)` class scope that uses SQLite LIKE across all columns.
module Searchable
  extend ActiveSupport::Concern

  class_methods do
    # Declares which columns are searched and defines the `.search` scope
    #
    # Columns of an association are searched through a subquery, so a record matches once
    # however many of its associated rows match: `searchable_on :name, account_numbers: :number`.
    #
    # @param columns [Array<Symbol>] Column names to include in search
    # @param associations [Hash{Symbol => Symbol}] Has-many association name => column on that table
    # @return [void]
    def searchable_on(*columns, **associations)
      @searchable_columns = columns

      scope :search, ->(query) {
        return none if query.blank?

        sanitized = "%#{sanitize_sql_like(query.to_s.strip)}%"
        conditions = columns.map { |col|
 "#{table_name}.#{col} LIKE ?" } + searchable_association_conditions(associations)
        where(conditions.join(" OR "), *conditions.map { sanitized }).limit(10)
      }
    end

    # Returns the declared searchable column names
    #
    # @return [Array<Symbol>]
    def searchable_columns
      @searchable_columns || []
    end

    # SQL fragments, one per association column, each with one LIKE placeholder
    #
    # @param associations [Hash{Symbol => Symbol}]
    # @return [Array<String>]
    def searchable_association_conditions(associations)
      associations.map do |name, column|
        reflection = reflect_on_association(name)
        "#{table_name}.#{primary_key} IN " \
          "(SELECT #{reflection.foreign_key} FROM #{reflection.table_name} WHERE #{column} LIKE ?)"
      end
    end
  end
end
