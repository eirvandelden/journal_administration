# Controller for marking an external account as a shared payment provider.
class Accounts::PaymentProvidersController < ApplicationController
  before_action :set_account

  # Marks the account as a shared payment provider.
  #
  # @action POST
  # @route /accounts/:account_id/payment_provider
  def create
    change(true, "payment_providers.create.success")
  end

  # Unmarks the account. Transactions already moved to merchants stay with them.
  #
  # @action DELETE
  # @route /accounts/:account_id/payment_provider
  def destroy
    change(false, "payment_providers.destroy.success")
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def change(provider, success_key)
    if @account.update(payment_provider: provider)
      redirect_to @account, notice: t(success_key)
    else
      redirect_to @account, alert: @account.errors.full_messages.to_sentence
    end
  end
end
