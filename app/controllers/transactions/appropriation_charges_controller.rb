module Transactions
  # Charges a whole payment to an appropriation, moves that charge, or removes it
  class AppropriationChargesController < ApplicationController
    before_action :set_transaction

    # Charges the payment to the chosen appropriation, moving any earlier charge.
    #
    # @action PATCH
    # @route /transactions/:transaction_id/appropriation_charge
    # @return [void]
    def update
      charge_to Appropriation.find(charge_params[:appropriation_id]), notice: t(".success")
    end

    # Removes the payment's charge; the payment itself stays.
    #
    # @action DELETE
    # @route /transactions/:transaction_id/appropriation_charge
    # @return [void]
    def destroy
      charge_to nil, notice: t(".success")
    end

    private

    # Finds the payment named in the path
    def set_transaction
      @transaction = Transaction.find(params[:transaction_id])
    end

    # Saves the charge and returns to editing the payment, naming why when it is refused
    def charge_to(appropriation, notice:)
      if @transaction.update(appropriation:)
        redirect_to edit_transaction_path(@transaction), notice:
      else
        redirect_to edit_transaction_path(@transaction), alert: @transaction.errors.full_messages.to_sentence
      end
    end

    # The appropriation a person chose
    def charge_params
      params.expect(appropriation_charge: [ :appropriation_id ])
    end
  end
end
