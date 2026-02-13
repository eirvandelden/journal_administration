# Represents a transaction category with hierarchical parent-child structure
#
# Categories have a direction (debit or credit) and can be organized hierarchically
# with a parent category. The Sortable concern provides ordering by hierarchy.
class Category < ApplicationRecord
  include Sortable

  DIRECTIONS = %i[debit credit].freeze

  # @!attribute [rw] direction
  #   @return [String] The category direction (debit or credit)
  enum direction: DIRECTIONS

  has_many :transactions
  has_many :secondaries, class_name: "Category",
                         foreign_key: "parent_category_id"

  belongs_to :parent_category, class_name: "Category", optional: true

  default_scope { order(name: :asc) }
  scope :groups, -> { where(parent_category_id: nil) }

  validates :direction, presence: true

  # Returns all children of this category plus itself
  #
  # @return [ActiveRecord::Relation] Self and all child categories
  def children
    Category.where(parent_category_id: id).or(Category.where(id: id))
  end

  # Returns the category name
  #
  # @return [String] Category name
  def to_s
    name
  end

  # Returns displayable full name including parent if this is a child category
  #
  # For child categories, returns "Parent Name - Child Name"
  # For parent categories, returns just the name
  #
  # @return [String] Full hierarchical category name
  def full_name
    if parent_category.present?
      "#{parent_category.name} - #{name}"
    else
      name
    end
  end
end
