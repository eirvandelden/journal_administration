# Represents a transaction category with hierarchical parent-child structure
#
# Categories have a direction (debit or credit) and can be organized hierarchically
# with a parent category. The Sortable concern provides ordering by hierarchy.
class Category < ApplicationRecord
  include Sortable
  include Searchable

  searchable_on :name

  # @!attribute [rw] direction
  #   @return [String] The category direction (debit or credit)
  enum :direction, { debit: 0, credit: 1 }

  has_many :transactions
  has_many :budget_categories
  has_many :secondaries, class_name: "Category",
                         foreign_key: "parent_category_id"

  belongs_to :parent_category, class_name: "Category", optional: true

  default_scope { order(name: :asc) }
  scope :groups, -> { where(parent_category_id: nil) }

  validates :direction, presence: true

  # Returns the most recent transactions for this category and its children
  #
  # @param limit [Integer] Maximum number of transactions to return
  # @return [ActiveRecord::Relation] Transactions ordered by most recent first
  def recent_transactions(limit: 10)
    matching_category_ids = children.select(:id)
    unsplit_transaction_ids = Transaction.where(category_id: matching_category_ids)
                                       .where.missing(:transaction_splits)
                                       .select(:id)
    split_transaction_ids = TransactionSplit.where(category_id: matching_category_ids).select(:transaction_id)

    Transaction
      .where(id: unsplit_transaction_ids)
      .or(Transaction.where(id: split_transaction_ids))
      .distinct
      .includes(:creditor, :debitor, :category, transaction_splits: :category)
      .order(booked_at: :desc, id: :desc)
      .limit(limit)
  end

  # Returns ids matched by this category's recent transaction views.
  #
  # Child categories match themselves; parent categories match all children.
  #
  # @return [Array<Integer>]
  def recent_transaction_category_ids
    @recent_transaction_category_ids ||= children.ids
  end

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
