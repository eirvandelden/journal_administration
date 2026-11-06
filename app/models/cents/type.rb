# Attribute type for money stored as Integer cents.
#
# Integers pass through as cents, text is read as euros through Cents.parse, and
# any other number raises, so that 12 and 12.0 can never mean different amounts.
class Cents::Type < ActiveModel::Type::Value
  # @return [Symbol]
  #: () -> Symbol
  def type = :integer

  # @param value [Integer, String, nil]
  # @return [Integer, nil] cents
  # @raise [ArgumentError] for a Float, BigDecimal or other non-Integer number
  #: (Integer | String | nil value) -> Integer?
  def cast(value)
    case value
    when nil, Integer then value
    when String then Cents.parse(value)
    when Numeric then raise ArgumentError, "convert #{value.class} euros with Cents.from_euros"
    end
  end

  # @return [Integer, nil]
  #: (Integer | String | nil value) -> Integer?
  def serialize(value) = cast(value)

  # @return [Integer, nil]
  #: (Integer | String | nil value) -> Integer?
  def deserialize(value) = value&.to_i
end
