# Manages linking transfers to source transactions
class TransactionLinksController < ApplicationController
  before_action :set_transaction

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
