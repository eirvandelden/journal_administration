class Session < ApplicationRecord
  include Appkit::SessionBehavior

  belongs_to :user
end
