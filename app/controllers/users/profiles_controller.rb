# Manages user profile information
#
# Users can view and edit their own profile. The UserScoped concern sets
# @user based on the params[:user_id] from the route.
class Users::ProfilesController < ApplicationController
  include UserScoped

  before_action :ensure_current_user, only: %i[edit update]

  # Displays a user's profile
  #
  # @return [void]
  def show
  end

  # Renders form for editing the current user's profile
  #
  # @return [void]
  def edit
  end

  # Updates the current user's profile information
  #
  # @return [void]
  def update
    @user.update!(user_params)
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address, :password)
  end
end
