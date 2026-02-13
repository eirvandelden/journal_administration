# Manages session transfers via email magic links
#
# Allows users to start a session using a transfer token sent via email,
# instead of typing a password.
class Sessions::TransfersController < ApplicationController
  allow_unauthenticated_access

  # Displays the magic link login page (shows confirmation message)
  #
  # @return [void]
  def show
  end

  # Authenticates a user via their email magic link token
  #
  # Validates the transfer_id token and creates a session if valid.
  # Returns 400 Bad Request if the token is invalid or expired.
  #
  # @return [void]
  def update
    if user = User.active.find_by_transfer_id(params[:id])
      start_new_session_for user
      redirect_to post_authenticating_url
    else
      head :bad_request
    end
  end
end
