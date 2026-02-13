# Provides authorization helpers for controllers
#
# Includes before_action callbacks and private helper methods for checking
# user permissions and returning 403 Forbidden responses when unauthorized.
module Authorization
  private

  def ensure_can_administer
    head :forbidden unless Current.user.can_administer?
  end

  def ensure_current_user
    head :forbidden unless @user.current?
  end
end
