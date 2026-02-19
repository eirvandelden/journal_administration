# Bulk updates to uncategorized transactions for an account
class Accounts::TransactionsBulkController < ApplicationController
  before_action :set_account

  # Updates all uncategorized transactions in an account to the account's category
  #
  # @return [void]
  def update
    updated_count = @account.update_uncategorized_transactions!
    flash[:notice] = "#{updated_count} transactions updated to category #{@account.category.name}."
    redirect_back fallback_location: accounts_url
  rescue BulkUpdatable::MissingCategoryError
    redirect_back fallback_location: accounts_url, alert: "Account has no category"
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
