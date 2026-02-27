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
  # Only updates uncategorized non-transfer transactions where this account has a
  # mutation. Transfer transactions are excluded because both mutations are on
  # family-owned accounts.
  #
  # @return [Integer] Number of transactions updated
  # @raise [MissingCategoryError] If the account has no default category
  def update_uncategorized_transactions!
    raise MissingCategoryError, I18n.t("accounts.errors.missing_category") if category.blank?

    Transaction.where(id: updatable_transaction_ids).update_all(category_id: category_id)
  end

  private

  def updatable_transaction_ids
    Transaction.where(category_id: nil)
               .where(id: transactions_for_account.select(:id))
               .where(id: non_transfer_transactions.select(:id))
  end

  def transactions_for_account
    Transaction.joins(:mutations).where(mutations: { account_id: id }).distinct
  end

  def non_transfer_transactions
    Transaction.joins(mutations: :account).where(accounts: { owner: nil }).distinct
  end
end
