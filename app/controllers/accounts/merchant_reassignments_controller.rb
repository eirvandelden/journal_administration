# Controller for moving a shared payment provider's transactions to their merchants.
class Accounts::MerchantReassignmentsController < ApplicationController
  before_action :set_account

  # Moves the provider's transactions to the merchants named in them.
  #
  # @action POST
  # @route /accounts/:account_id/merchant_reassignment
  def create
    count = @account.move_transactions_to_merchants
    redirect_to @account, notice: t("merchant_reassignments.create.success", count: count)
  rescue PaymentProvider::MoveFailed => error
    redirect_to @account, alert: t("merchant_reassignments.create.failure", message: error.message)
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
