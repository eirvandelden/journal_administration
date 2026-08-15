# Helpers for rendering the todo list.
module TodosHelper
  # Renders a todo item's description: the outstanding note and amount for a
  # transaction, or the account's name.
  #
  # @param item [Todo::Item] the todo item
  # @return [String] the description
  def todo_description(item)
    return item.record.to_s unless item.kind == :transaction

    safe_join([ item.record.note&.truncate(40), number_to_currency(item.record.uncategorized_amount) ].compact, " ")
  end
end
