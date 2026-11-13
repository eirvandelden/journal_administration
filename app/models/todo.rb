# Provides data for the Alles page
#
# Aggregates the open items of Verwerken (transactions to consolidate,
# untouched accounts and unclassified products) into a single date-sorted list.
class Todo
  extend ActiveModel::Naming

  # Lightweight container for a combined todo list item
  #
  # @!attribute [r] kind
  #   @return [Symbol] :transaction, :account or :product
  # @!attribute [r] date
  #   @return [ActiveSupport::TimeWithZone, nil] Sort date for the item
  # @!attribute [r] record
  #   @return [Transaction, Account, Product] The underlying AR record
  Item = Struct.new(
    :kind,   #: Symbol
    :date,   #: ActiveSupport::TimeWithZone?
    :record  #: Transaction | Account | Product
  )

  # Returns the combined, date-sorted list of transactions to consolidate,
  # untouched accounts and unclassified products
  #
  # The three scopes are the ones the Verwerken pages count, so the Alles tile
  # shows as many items as this list holds. Items are sorted newest-first.
  #
  # @return [Array<Todo::Item>]
  #: () -> Array[Item]
  def items
    @items ||= (transaction_items + account_items + product_items).sort_by { |item| -item.date.to_i }
  end

  # Returns whether the combined list is empty
  #
  # @return [Boolean]
  #: () -> bool
  def empty?
    items.empty?
  end

  private

  def transaction_items
    Transaction.uncategorized.order(booked_at: :desc)
               .map { |t| Item.new(:transaction, t.booked_at, t) }
  end

  def account_items
    Account.untouched.order(created_at: :desc)
           .map { |a| Item.new(:account, a.created_at, a) }
  end

  def product_items
    Product.unclassified.order(created_at: :desc)
           .map { |product| Item.new(:product, product.created_at, product) }
  end
end
