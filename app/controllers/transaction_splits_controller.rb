# Manages splits of a transaction's amount across categories
class TransactionSplitsController < ApplicationController
  before_action :set_transaction

  # Adds a split to the transaction
  #
  # @action POST
  # @route /transactions/:transaction_id/transaction_splits
  def create
    @transaction_split = @transaction.transaction_splits.build(split_params)

    respond_to do |format|
      if @transaction_split.save
        @transaction.ensure_remainder_split
        format.turbo_stream
        format.html { redirect_to edit_transaction_path(@transaction) }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to edit_transaction_path(@transaction) }
      end
    end
  end

  # Updates an existing split
  #
  # @action PATCH
  # @route /transactions/:transaction_id/transaction_splits/:id
  def update
    @transaction_split = @transaction.transaction_splits.find(params[:id])

    respond_to do |format|
      if @transaction_split.update(split_params)
        @transaction.ensure_remainder_split
        format.turbo_stream
        format.html { redirect_to edit_transaction_path(@transaction) }
      else
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { redirect_to edit_transaction_path(@transaction) }
      end
    end
  end

  # Removes a split from the transaction
  #
  # @action DELETE
  # @route /transactions/:transaction_id/transaction_splits/:id
  def destroy
    @transaction_split = @transaction.transaction_splits.find(params[:id])
    @transaction_split.destroy
    @transaction.ensure_remainder_split

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_transaction_path(@transaction) }
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end

  def split_params
    params.require(:transaction_split).permit(:category_id, :amount, :note)
  end
end
