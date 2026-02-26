# Provides bulk categorization of uncategorized transactions
#
# Allows accounts to apply their default category to all uncategorized transactions
# in a single operation. Transfer transactions are excluded due to their special nature.
module BulkUpdatable
  extend ActiveSupport::Concern

  # Raised when attempting to bulk-update with an account that has no default category
  class MissingCategoryError < StandardError; end

  # Updates all uncategorized transactions for this account to its default category
  #
  # Only updates transactions where this account is either debitor or creditor.
  # Transfer transactions are explicitly excluded because they involve two family
  # accounts and would require ambiguous categorization logic.
  #
  # @return [Integer] Number of transactions updated
  # @raise [MissingCategoryError] If the account has no default category
  def update_uncategorized_transactions!
    raise MissingCategoryError, "Account must have a category" if category.blank?

    Transaction.where(category_id: nil, type: updatable_transaction_types)
               .where("debitor_account_id = :account_id OR creditor_account_id = :account_id", account_id: id)
               .update_all(category_id: category_id)
  end

  private

  def updatable_transaction_types
    Transaction::TYPES - ["Transfer"]
  end
end
