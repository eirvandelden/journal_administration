class ApplicationController < ActionController::Base
  include Clearance::Controller
  include Pagy::Backend

  before_action :require_login
end
