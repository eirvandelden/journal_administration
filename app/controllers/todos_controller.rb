# Displays Alles: every open item of Verwerken in one list
#
# Shows transactions to consolidate, untouched accounts and unclassified products.
class TodosController < ApplicationController
  PER_PAGE = 20

  Page = Struct.new(
    :number,      #: Integer
    :total_pages  #: Integer
  )

  class Page
    #: () -> bool
    def last?      = number >= total_pages

    #: () -> bool
    def before_last? = number < total_pages

    #: () -> Integer
    def next_param = number + 1
  end

  # Renders the Alles page
  #
  # @return [void]
  #: () -> void
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
