# Manages user authentication sessions
#
# Handles login (new/create) and logout (destroy) with rate limiting and email-based authentication.
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render_rejection :too_many_requests }

  before_action :ensure_user_exists, only: :new

  # Renders the login form
  #
  # Redirects to first_run_url if no users exist in the system.
  #
  # @return [void]
  def new
  end

  # Authenticates a user by email and password
  #
  # On success, creates a session and redirects to the app.
  # On failure, re-renders login form with error message.
  # Rate-limited to 10 attempts per 3 minutes.
  #
  # @return [void]
  def create
    if user = User.active.authenticate_by(email_address: params[:email_address], password: params[:password])
      start_new_session_for user
      redirect_to post_authenticating_url
    else
      render_rejection :unauthorized
    end
  end

  # Destroys the current session and logs out the user
  #
  # @return [void]
  def destroy
    reset_authentication

    redirect_to root_url
  end

  private

  def ensure_user_exists
    redirect_to first_run_url if User.none?
  end

  def render_rejection(status)
    flash[:alert] = "Too many requests or unauthorized."
    render :new, status: status
  end
end
