# Manages linking transfers to source transactions
class TransactionLinksController < ApplicationController
  before_action :set_transaction

  # Searches for unlinked Transfer transactions
  #
  # @action GET
  # @route /transactions/:transaction_id/transaction_links
  def index
    searching = params[:query].present? || params[:amount].present?

    @transfers = if searching
      scope = Transaction.unscoped
        .where(type: "Transfer")
        .where.missing(:reverse_transaction_links)
        .where.not(id: @transaction.linked_transfer_ids)
        .joins("LEFT JOIN accounts AS creditors ON creditors.id = transactions.creditor_account_id")
        .joins("LEFT JOIN accounts AS debitors ON debitors.id = transactions.debitor_account_id")
        .order(booked_at: :desc)
        .limit(20)

      if params[:query].present?
        scope = scope.where(
          "transactions.note LIKE :q OR creditors.name LIKE :q OR debitors.name LIKE :q",
          q: "%#{params[:query]}%"
        )
      end

      if params[:amount].present?
        scope = scope.where(amount: params[:amount].to_d)
      end

      scope
    else
      Transaction.none
    end
  end

  # Links a transfer to the source transaction
  #
  # @action POST
  # @route /transactions/:transaction_id/transaction_links
  def create
    @transaction_link = @transaction.transaction_links.build(transfer_id: params[:transfer_id])

    respond_to do |format|
      if @transaction_link.save
        format.turbo_stream
        format.html { redirect_to edit_transaction_path(@transaction) }
      else
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to edit_transaction_path(@transaction) }
      end
    end
  end

  # Removes a link between a transfer and the source transaction
  #
  # @action DELETE
  # @route /transactions/:transaction_id/transaction_links/:id
  def destroy
    @transaction_link = @transaction.transaction_links.find(params[:id])
    @transaction_link.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_transaction_path(@transaction) }
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end
end
