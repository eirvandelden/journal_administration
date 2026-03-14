# Manages recognition patterns for an account
class Accounts::AccountAliasesController < ApplicationController
  before_action :set_account

  # Creates a new alias pattern for the account
  #
  # @action POST
  # @route /accounts/:account_id/account_aliases
  def create
    @account_alias = @account.account_aliases.build(account_alias_params)

    if @account_alias.save
      redirect_to @account, notice: t("account_aliases.create.success")
    else
      redirect_to @account, alert: @account_alias.errors.full_messages.to_sentence
    end
  end

  # Removes an alias pattern from the account
  #
  # @action DELETE
  # @route /accounts/:account_id/account_aliases/:id
  def destroy
    @account.account_aliases.find(params[:id]).destroy
    redirect_to @account, notice: t("account_aliases.destroy.success")
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def account_alias_params
    params.expect(account_alias: [ :pattern ])
  end
end
