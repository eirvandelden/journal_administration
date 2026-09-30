# Lets a payment, or one part of it, count against an appropriation
#
# Charging never touches the category: the monthly budget keeps counting it as before.
module Chargeable
  extend ActiveSupport::Concern

  included do
    belongs_to :appropriation, optional: true
  end
end
