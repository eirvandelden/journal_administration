# Bulk updates to uncategorized transactions for an account
class Accounts::TransactionsBulkController < ApplicationController
  before_action :set_account

  # Updates all uncategorized transactions in an account to the account's category
  #
  # @return [void]
  def update
    updated_count = @account.update_uncategorized_transactions!
    flash[:notice] = t("accounts.transactions_bulk.update.success", count: updated_count, category: @account.category.name)
    redirect_back fallback_location: accounts_url
  rescue BulkUpdatable::MissingCategoryError
    redirect_back fallback_location: accounts_url, alert: t("accounts.transactions_bulk.update.no_category")
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
