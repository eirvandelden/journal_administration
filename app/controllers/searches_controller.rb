# Handles global search requests
class SearchesController < ApplicationController
  # Renders search results for the given query
  #
  # @action GET
  # @route /searches
  def index
    @search = Search.new(query: params[:q])
  end
end
