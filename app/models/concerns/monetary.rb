# Declares money attributes stored as Integer cents
#
#   monetary :amount
#
# A user's text such as "1,50" is read as 150. Text that is not an amount fails
# validation instead of silently becoming blank.
module Monetary
  extend ActiveSupport::Concern

  class_methods do
    # @param names [Array<Symbol>] attributes that hold cents
    # @return [void]
    def monetary(*names)
      names.each do |name|
        attribute name, Cents::Type.new
        validate { errors.add(name, :not_an_amount) if unreadable_amount?(name) }
      end
    end
  end

  private

  def unreadable_amount?(name)
    typed = public_send(:"#{name}_before_type_cast")
    typed.is_a?(String) && typed.present? && public_send(name).nil?
  end
end
