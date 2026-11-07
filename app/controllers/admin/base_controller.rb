class Admin::BaseController < ApplicationController
  before_action :ensure_admin

  private

  def ensure_admin
    redirect_to root_path, alert: t("errors.admin_required") unless Current.user&.administrator?
  end
end
