# Adds role behavior to users.
module User::Role
  extend ActiveSupport::Concern

  included do
    enum :role, %i[ member administrator ], default: :member
  end

  # Indicates whether the user can access admin features.
  #
  # @return [Boolean]
  def can_administer?
    administrator?
  end
end
