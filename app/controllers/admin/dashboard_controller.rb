class Admin::DashboardController < Admin::BaseController
  def index
    @users = User.all.order(created_at: :desc).limit(10)
    @total_users = User.count
    @admin_users = User.administrator.count
  end
end
