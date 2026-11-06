# Provides hierarchical sorting for categories
#
# Sorts categories with proper parent-child relationships, placing parent
# categories before their children alphabetically.
module Sortable
  extend ActiveSupport::Concern

  class_methods do
    # Sorts a hash of records by hierarchical order
    #
    # Parent categories sort before their children. Within a group, both parents
    # and children sort alphabetically.
    #
    #: (Hash[Category?, Integer] records_hash) -> Hash[Category?, Integer]
    def sort_by_hierarchy(records_hash)
      records_hash.sort_by { |record, _amount|
        hierarchy_sort_key(record)
      }.to_h
    end

    # Generates a sort key for a record based on its hierarchy
    #
    # Returns a three-element array for consistent sorting:
    # [parent_name, hierarchy_level, record_name]
    #
    # @param record [Category, nil] The category record
    # @return [Array] A sort key suitable for comparison
    private def hierarchy_sort_key(record)
      return [ "", 0, "" ] if record.nil?
      return [ record.name.downcase, 0, "" ] if record.parent_category.nil?

      [ record.parent_category.name.downcase, 1, record.name.downcase ]
    end
  end
end
