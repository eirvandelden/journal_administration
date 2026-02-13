# Manages user accounts with role-based access control
#
# Handles user signup (requires valid join code) and admin-only user management
# (update roles, deactivate users).
class UsersController < ApplicationController
  require_unauthenticated_access only: %i[new create]

  before_action :verify_join_code, only: %i[new create]
  before_action :ensure_can_administer, only: %i[update destroy]
  before_action :set_user, only: %i[update destroy]

  # Lists all active users
  #
  # Admin-only action. Shows members and administrators.
  #
  # @return [void]
  def index
    @users = User.active
  end

  # Renders the user signup form
  #
  # Requires a valid join_code to access (set per account).
  #
  # @return [void]
  def new
    @user = User.new
  end

  # Creates a new user and starts a session
  #
  # Requires a valid join_code. On duplicate email, redirects to login.
  #
  # @return [void]
  def create
    @user = User.create!(user_params)
    start_new_session_for @user
    redirect_to root_url
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_url(email_address: user_params[:email_address])
  end

  # Updates a user's role (admin-only)
  #
  # @return [void]
  def update
    @user.update(role_params)
    redirect_to users_url
  end

  # Deactivates a user (admin-only)
  #
  # @return [void]
  def destroy
    @user.deactivate
    redirect_to users_url
  end

  private

  def role_params
    { role: params.require(:user)[:role].presence_in(%w[member administrator]) || "member" }
  end

  def set_user
    @user = User.active.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email_address, :password)
  end

  def verify_join_code
    head :not_found if Current.account.join_code != params[:join_code]
  end
end
