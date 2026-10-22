# Folds duplicate external accounts into the account they are merged on.
class Accounts::MergesController < ApplicationController
  before_action :set_account

  # Searches for duplicates, then reviews the picked ones with the counts that move.
  #
  # @action GET
  # @route /accounts/:account_id/merge/new
  def new
    @query = merge_params[:query].to_s.strip
    @matches = candidates.includes(:account_numbers).search(@query)
    @duplicates = candidates.where(id: duplicate_ids).order(:id).includes(:account_numbers).load
    @transactions_count = duplicate_ids.any? ? Transaction.by_account(@duplicates.ids).count : 0
    @receipts_count = Receipt.where(shop_id: @duplicates.ids).count
  end

  # Merges the picked duplicates into the account.
  #
  # @action POST
  # @route /accounts/:account_id/merge
  def create
    duplicates = Account.where(id: duplicate_ids).to_a
    transactions = Transaction.by_account(duplicates.map(&:id)).count
    receipts = Receipt.where(shop_id: duplicates.map(&:id)).count

    if @account.merge(duplicates)
      redirect_to @account, notice: t(".success", transactions: t(".transactions", count: transactions),
        receipts: t(".receipts", count: receipts), accounts: t(".accounts", count: duplicates.size))
    else
      redirect_to new_account_merge_path(@account, duplicate_ids:), alert: @account.errors.full_messages.to_sentence
    end
  end

  private

  def set_account
    @account = Account.find(params[:account_id])
  end

  def merge_params
    params.permit(:query, duplicate_ids: [])
  end

  def candidates
    Account.external.where.not(id: @account.id)
  end

  def duplicate_ids
    Array(merge_params[:duplicate_ids]).compact_blank.map(&:to_i)
  end
end
