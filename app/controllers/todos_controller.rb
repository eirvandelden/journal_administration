# Displays the consolidated todo list for outstanding data actions
#
# Shows uncategorized transactions, untouched accounts, and optionally a CSV
# upload form when no recent imports have been made.
class TodosController < ApplicationController
  # Renders the todo index page
  #
  # @return [void]
  def index
    todo = Todo.new

    @show_upload_form = todo.show_upload_form?
    @items            = todo.items
    @empty            = todo.empty?
  end
end
