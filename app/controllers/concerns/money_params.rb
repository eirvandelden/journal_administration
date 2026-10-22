# Reads numeric JSON money amounts, which are euros, as cents.
module MoneyParams
  extend ActiveSupport::Concern

  private

  # Converts numeric values under the given keys with Cents.from_euros. A number with a
  # fraction of a cent becomes text, so the model refuses it as not an amount.
  #
  # @param permitted [ActionController::Parameters]
  # @param keys [Array<Symbol>]
  # @return [ActionController::Parameters] a copy; the given parameters stay unchanged
  def euros_to_cents(permitted, *keys)
    numbers = permitted.slice(*keys).to_h.select { |_key, value| value.is_a?(Numeric) }
    permitted.merge(numbers.transform_values { |number| cents_from(number) })
  end

  def cents_from(number)
    Cents.from_euros(number)
  rescue ArgumentError
    number.to_s
  end
end
