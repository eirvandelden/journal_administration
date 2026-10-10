module TransactionSplits
  # Charges one explicit part of a split payment to an appropriation, moves that charge, or removes it
  class AppropriationChargesController < ApplicationController
    before_action :set_transaction_split

    # Charges the part to the chosen appropriation, moving any earlier charge.
    #
    # @action PATCH
    # @route /transactions/:transaction_id/transaction_splits/:transaction_split_id/appropriation_charge
    # @return [void]
    def update
      charge_to Appropriation.find(charge_params[:appropriation_id]), notice: t(".success")
    end

    # Removes the part's charge; the part itself stays.
    #
    # @action DELETE
    # @route /transactions/:transaction_id/transaction_splits/:transaction_split_id/appropriation_charge
    # @return [void]
    def destroy
      charge_to nil, notice: t(".success")
    end

    private

    # Finds the explicit part named in the path, only among its own payment's parts
    def set_transaction_split
      @transaction = Transaction.find(params[:transaction_id])
      @transaction_split = @transaction.explicit_transaction_splits.find(params[:transaction_split_id])
    end

    # Saves the charge and returns to editing the payment, naming why when it is refused
    def charge_to(appropriation, notice:)
      if @transaction_split.update(appropriation:)
        redirect_to edit_transaction_path(@transaction), notice:
      else
        redirect_to edit_transaction_path(@transaction), alert: @transaction_split.errors.full_messages.to_sentence
      end
    end

    # The appropriation a person chose
    def charge_params
      params.expect(appropriation_charge: [ :appropriation_id ])
    end
  end
end
