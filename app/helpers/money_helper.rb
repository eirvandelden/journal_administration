# Shows money that is stored as Integer cents.
module MoneyHelper
  # Renders cents as currency, the way the euro amount rendered before cents.
  #
  # @param cents [Integer, nil]
  # @param options [Hash] passed to number_to_currency
  # @return [String, nil]
  def cents_to_currency(cents, **options)
    number_to_currency(Cents.to_euros(cents), **options)
  end

  # The value to put in a money form field.
  #
  # Text the user typed that could not be read comes back unchanged, so the form
  # shows what they typed. Otherwise the cents show as euros with two decimals.
  #
  # @param record [ActiveRecord::Base]
  # @param attribute [Symbol]
  # @param separator [String] decimal separator of the field: the locale's for text fields, "." for number fields
  # @return [String, nil]
  def cents_field_value(record, attribute, separator:)
    cents = record.public_send(attribute)
    typed = record.public_send(:"#{attribute}_before_type_cast")
    return typed if cents.nil? && typed.is_a?(String) && typed.present?
    return if cents.nil?

    format("%.2f", Cents.to_euros(cents)).tr(".", separator)
  end
end
