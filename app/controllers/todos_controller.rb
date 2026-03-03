# Displays the consolidated todo list for outstanding data actions
#
# Shows uncategorized transactions, untouched accounts, and optionally a CSV
# upload form when no recent imports have been made.
class TodosController < ApplicationController
  PER_PAGE = 20

  Page = Struct.new(:number, :total_pages) do
    def last?      = number >= total_pages
    def next_param = number + 1
  end

  # Renders the todo index page
  #
  # @return [void]
  def index
    todo      = Todo.new
    all_items = todo.items

    total_pages = [(all_items.size.to_f / PER_PAGE).ceil, 1].max
    page_number = [[params[:page].to_i, 1].max, total_pages].min

    @show_upload_form = todo.show_upload_form?
    @empty            = todo.empty?
    @page             = Page.new(page_number, total_pages)
    @items            = all_items[(@page.number - 1) * PER_PAGE, PER_PAGE] || []
  end
end
