# Keeps one delivery per Albert Heijn order number, holding the best basket known for it
#
# A delivery is identified by its order number, so a mail that arrives twice updates the delivery
# already recorded instead of adding a second one. A packing slip says what was packed and an order
# confirmation only what was ordered, so a confirmation never replaces the lines of a packing slip.
# A changed basket on a delivery whose payment is linked splits that payment again, so the books
# follow the corrected basket.
module Receipt::Recordable
  extend ActiveSupport::Concern

  FIRST_DELIVERY_ON = Date.new(2022, 11, 1)
  SHOP_NAME = "Albert Heijn B.V.".freeze

  class_methods do
    # Records the basket as the delivery of its order number, and returns that delivery
    #
    # A confirmation never replaces a packed basket, and a basket equal to the one recorded writes
    # nothing. The basket is any reader of `Importing::AlbertHeijn::BasketMail`.
    #
    #: (untyped basket) -> Receipt
    def record_basket(basket)
      transaction { find_or_initialize_by(order_number: basket.order_number).record(basket) }
    end
  end

  # Takes the basket on as this delivery's, unless it adds nothing or would lose a packed basket
  #
  #: (untyped basket) -> Receipt
  def record(basket)
    replace_basket(basket) unless keeps_packed_basket?(basket) || same_basket?(basket)

    self
  end

  private

  def keeps_packed_basket?(basket) = persisted? && packed? && !basket.packed?

  def same_basket?(basket)
    persisted? && issued_on == basket.delivered_on && total_amount == basket.total_amount &&
      packed? == basket.packed? && recorded_lines == basket.lines.map { |line| line_summary(line) }
  end

  def recorded_lines
    lines.includes(:product).order(:id).map do |line|
      [ line.product.normalized_name, line.quantity, line.full_amount, line.discount_amount, line.paid_amount ]
    end
  end

  def line_summary(line)
    [ line.name.strip.downcase, line.quantity, line.full_amount, line.discount_amount, line.paid_amount ]
  end

  def replace_basket(basket)
    update!(
      shop: albert_heijn, issued_on: basket.delivered_on, total_amount: basket.total_amount, packed: basket.packed?
    )
    lines.destroy_all
    basket.lines.each { |line| lines.create!(line_attributes(line)) }
    rewrite_payment_splits
  end

  def albert_heijn
    Account.resolve_for_import(account_number: nil, description: "", name: SHOP_NAME)
  end

  def line_attributes(line)
    {
      product: Product.resolve_by_name(line.name),
      quantity: line.quantity,
      full_amount: line.full_amount,
      discount_amount: line.discount_amount,
      paid_amount: line.paid_amount
    }
  end
end
