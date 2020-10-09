class User < ApplicationRecord
  include Clearance::User

  def admin?
    email == "etienne@vandelden.family"
  end
end
