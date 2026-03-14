# Controller for absorbing transactions from duplicate external accounts.
class Accounts::TransactionAbsorptionsController < ApplicationController
  before_action :set_account

  # Reassigns transactions from duplicate accounts to this account.
  #
  # @action POST
  # @route /accounts/:account_id/transaction_absorption
  def create
    @account.absorb_transactions_from_aliases
    redirect_to @account, notice: t("transaction_absorptions.create.success")
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end
end
