# Controller for moving a shared payment provider's transactions to their merchants.
class Accounts::MerchantReassignmentsController < ApplicationController
  before_action :set_account

  # Moves the provider's transactions to the merchants named in them.
  #
  # @action POST
  # @route /accounts/:account_id/merchant_reassignment
  #: () -> void
  def create
    count = @account.move_transactions_to_merchants
    redirect_to carried_path(@account), notice: t("merchant_reassignments.create.success", count: count)
  rescue PaymentProvider::MoveFailed => error
    alert = t("merchant_reassignments.create.failure", message: error.message)
    redirect_to carried_path(@account), alert:
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
