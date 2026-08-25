# Shows the grocery invoices we know and what each one held
class ReceiptsController < ApplicationController
  before_action :set_receipt, only: %i[show]

  # Lists the invoices, most recent first
  #
  # @return [void]
  def index
    @receipts = set_page_and_extract_portion_from receipts, per_page: [ 20 ]
  end

  # Displays one invoice with its basket, and the payments that could settle it
  #
  # @return [void]
  def show
    @candidate_payments = @receipt.payment ? Transaction.none : @receipt.fitting_payments
  end

  private

  def receipts
    Receipt.includes(:shop, :payment).order(issued_on: :desc)
  end

  def set_receipt
    @receipt = Receipt.includes(lines: { product: :product_type }).find(params[:id])
  end
end
