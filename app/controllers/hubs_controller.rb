# Shows a hub's landing page: one tile per page.
class HubsController < ApplicationController
  # Renders the tiles of the hub named in the path; an unknown or page-less hub is a 404.
  #
  # @action GET
  # @route /hubs/:id
  #: () -> void
  def show
    @hub = menu.hubs.find { |hub| hub.key.to_s == params[:id] && hub.pages.any? }
    raise ActiveRecord::RecordNotFound unless @hub
  end
end
