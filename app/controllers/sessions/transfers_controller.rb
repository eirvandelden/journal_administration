# Manages session transfers via email magic links
#
# Allows users to start a session using a transfer token sent via email,
# instead of typing a password.
class Sessions::TransfersController < ApplicationController
  allow_unauthenticated_access

  # Displays the magic-link login page.
  #
  # @action GET
  # @route /session/transfers/:id
  def show
  end

  # Authenticates a user via their email magic-link token.
  #
  # @action PUT
  # @route /session/transfers/:id
  def update
    if user = User.active.find_by_transfer_id(params[:id])
      start_new_session_for user
      redirect_to post_authenticating_url
    else
      head :bad_request
    end
  end
end
