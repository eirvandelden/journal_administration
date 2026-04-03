# A per-category allocation within a budget.
#
# Associates a Category with a Budget and stores the planned spending amount.
# The category must be a top-level (parent) category.
class BudgetCategory < ApplicationRecord
  belongs_to :budget
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :budget_id, uniqueness: { scope: :category_id }
  validate :category_must_be_parent
  validate :category_must_not_be_transfer

  private

  # @return [void]
  def category_must_be_parent
    return unless category.present?

    errors.add(:category, :must_be_parent) if category.parent_category_id.present?
  end

  # @return [void]
  def category_must_not_be_transfer
    return unless category.present?

    errors.add(:category, :must_not_be_transfer) if category.transfer?
  end
end
