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
    @transactions_count = transactions_in(@duplicates.ids)
    @transactions_by_account = Account.transactions_count_by_account(@duplicates.ids)
    @receipts_by_account = Account.receipts_count_by_account(@duplicates.ids)
    @receipts_count = @receipts_by_account.values.sum
  end

  # Merges the picked duplicates into the account.
  #
  # @action POST
  # @route /accounts/:account_id/merge
  def create
    duplicates = Account.where(id: duplicate_ids).to_a
    transactions = transactions_in(duplicates.map(&:id))
    receipts = Account.receipts_count_by_account(duplicates.map(&:id)).values.sum

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

  # Transactions on either side of the accounts; none for no accounts, as `by_account` would match all
  def transactions_in(ids)
    ids.any? ? Transaction.by_account(ids).count : 0
  end
end
