# Provides data for the todo page
#
# Aggregates uncategorized transactions and untouched accounts into a single
# date-sorted list, and determines whether a CSV upload prompt is needed.
class Todo
  extend ActiveModel::Naming

  # Number of days after which the CSV upload prompt is shown
  UPLOAD_PROMPT_THRESHOLD = 13

  # Lightweight container for a combined todo list item
  #
  # The date is the sort date for the item.
  Item = Struct.new(
    :kind,   #: (:transaction | :account | :product)
    :date,   #: ActiveSupport::TimeWithZone?
    :record  #: (Transaction | Account | Product)
  )

  # Returns whether a CSV upload form should be shown
  #
  # True when no transactions exist yet, or when the most recently booked
  # transaction is older than UPLOAD_PROMPT_THRESHOLD days.
  #
  #: () -> bool
  def show_upload_form?
    @show_upload_form ||= begin
      latest = Transaction.maximum(:booked_at)
      latest.nil? || latest < UPLOAD_PROMPT_THRESHOLD.days.ago
    end
  end

  # Returns the combined, date-sorted list of uncategorized transactions and
  # untouched accounts
  #
  # Uncategorized transactions are those with no category, an uncategorized
  # split, or a remaining uncategorized split balance.
  # Untouched accounts are those where updated_at equals created_at
  # (never modified since their initial import).
  # Items are sorted newest-first by their respective dates.
  #
  #: () -> Array[Todo::Item]
  def items
    @items ||= (transaction_items + account_items + product_items).sort_by { |item| -item.date.to_i }
  end

  # Returns whether the combined list is empty
  #
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
    Account.where("updated_at = created_at").order(created_at: :desc)
           .map { |a| Item.new(:account, a.created_at, a) }
  end

  def product_items
    Product.unclassified.order(created_at: :desc)
           .map { |product| Item.new(:product, product.created_at, product) }
  end
end
