# Controller for marking an external account as a shared payment provider.
class Accounts::PaymentProvidersController < ApplicationController
  before_action :set_account

  # Marks the account as a shared payment provider.
  #
  # @action POST
  # @route /accounts/:account_id/payment_provider
  def create
    update_and_redirect(payment_provider: true)
  end

  # Unmarks the account. Transactions already moved to merchants stay with them.
  #
  # @action DELETE
  # @route /accounts/:account_id/payment_provider
  def destroy
    update_and_redirect(payment_provider: false)
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def update_and_redirect(attributes)
    if @account.update(attributes)
      redirect_to @account, notice: t("payment_providers.#{action_name}.success")
    else
      redirect_to @account, alert: @account.errors.full_messages.to_sentence
    end
  end
end
