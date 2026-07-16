# Manages user accounts with role-based access control
#
# Handles admin-only user management (update roles, deactivate users).
class UsersController < ApplicationController
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
end
