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

        terms = searchable_terms(query.to_s.strip, columns, associations)
        where(terms.map(&:first).join(" OR "), *terms.map(&:last)).limit(10)
      }
    end

    # Returns the declared searchable column names
    #
    # @return [Array<Symbol>]
    def searchable_columns
      @searchable_columns || []
    end

    # Pairs of a SQL fragment with one LIKE placeholder and its pattern, one per searched column
    #
    # The query is normalized the way the association's model normalizes the column.
    #
    # @param query [String]
    # @param columns [Array<Symbol>]
    # @param associations [Hash{Symbol => Symbol}]
    # @return [Array<Array(String, String)>]
    def searchable_terms(query, columns, associations)
      own = columns.map { |column| [ "#{table_name}.#{column} LIKE ?", like_pattern(query) ] }
      own + associations.map { |name, column| searchable_association_term(query, name, column) }
    end

    # @return [Array(String, String)]
    def searchable_association_term(query, name, column)
      reflection = reflect_on_association(name)
      sql = "#{table_name}.#{primary_key} IN " \
        "(SELECT #{reflection.foreign_key} FROM #{reflection.table_name} WHERE #{column} LIKE ?)"
      [ sql, like_pattern(reflection.klass.normalize_value_for(column, query)) ]
    end

    # @return [String]
    def like_pattern(text)
      "%#{sanitize_sql_like(text)}%"
    end
  end
end
