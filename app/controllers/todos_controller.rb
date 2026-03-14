# Displays the consolidated todo list for outstanding data actions
#
# Shows uncategorized transactions and untouched accounts.
class TodosController < ApplicationController
  PER_PAGE = 20

  Page = Struct.new(:number, :total_pages) do
    def last?      = number >= total_pages
    def before_last? = number < total_pages
    def next_param = number + 1
  end

  # Renders the todo index page
  #
  # @return [void]
  def index
    todo = Todo.new
    @empty = todo.empty?
    @items = paginated_items(todo.items)
  end

  private
    def paginated_items(items)
      @page = build_page(total_items: items.size)
      items.slice((@page.number - 1) * PER_PAGE, PER_PAGE) || []
    end

    def build_page(total_items:)
      total_pages = [ (total_items.to_f / PER_PAGE).ceil, 1 ].max
      page_number = [ [ params[:page].to_i, 1 ].max, total_pages ].min
      Page.new(page_number, total_pages)
    end
end
