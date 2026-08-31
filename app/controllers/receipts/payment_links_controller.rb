module Receipts
  # Settles a receipt against the payment a person picked for it
  class PaymentLinksController < ApplicationController
    before_action :set_receipt

    # Links the chosen payment to the receipt and splits it by the basket
    #
    # @return [void]
    def create
      payment = chosen_payment
      return redirect_to @receipt, alert: t(".basket_exceeds_payment") unless @receipt.basket_fits?(payment)

      @receipt.update!(payment: payment)
      @receipt.rewrite_payment_splits

      redirect_to @receipt, notice: t(".success")
    end

    # Lets a person undo settling the wrong payment. The splits already written
    # stay as they are: what the payment carried before is not recoverable.
    #
    # @return [void]
    def destroy
      @receipt.update!(payment: nil)

      redirect_to @receipt, notice: t(".success")
    end

    private

    def set_receipt
      @receipt = Receipt.find(params[:receipt_id])
    end

    # Only a payment the receipt could plausibly belong to may be chosen
    def chosen_payment
      @receipt.fitting_payments.find(payment_params[:payment_id])
    end

    def payment_params
      params.expect(receipt: [ :payment_id ])
    end
  end
end
