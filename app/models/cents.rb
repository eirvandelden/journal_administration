# Conversions between money text, decimal euros and whole cents.
#
# Money is stored and calculated as Integer cents. This module holds the one rule
# for reading what a user types and for showing cents as euros.
module Cents
  AMOUNT = /\A(?<sign>-)?(?<digits>\d[\d.,]*)\z/
  GROUPED = /\A\d{1,3}([.,]\d{3})+\z/
  SEPARATOR_WITH_CENTS = /\A(?<whole>.*?)[.,](?<cents>\d{1,2})\z/

  # Reads money text such as "1,50", "1.5" or "1.234,56" as cents.
  #
  # The last "," or "." followed by one or two digits is the decimal separator;
  # every other separator must start a group of exactly three digits. A lone
  # separator followed by three digits ("1.500") is ambiguous and is refused.
  #
  # @param text [String, nil]
  # @return [Integer, nil] cents, or nil when the text is not an amount
  def self.parse(text)
    match = AMOUNT.match(text.to_s.strip) or return
    whole, cents = split_decimals(match[:digits])
    return unless whole

    value = (whole.to_i * 100) + cents
    match[:sign] ? -value : value
  end

  # Converts a number in euros to cents without float noise.
  #
  # @param euros [Numeric]
  # @return [Integer] cents
  # @raise [ArgumentError] when the amount has a fraction of a cent
  def self.from_euros(euros)
    cents = BigDecimal(euros.to_s) * 100
    raise ArgumentError, "#{euros} has a fraction of a cent" unless cents.frac.zero?

    cents.to_i
  end

  # @param cents [Integer, nil]
  # @return [BigDecimal, nil] euros
  def self.to_euros(cents)
    return if cents.nil?

    BigDecimal(cents) / 100
  end

  # @return [Array(String, Integer), nil] whole euros as digits and the cents
  def self.split_decimals(digits)
    match = SEPARATOR_WITH_CENTS.match(digits)
    return whole_euros(digits) unless match

    whole = match[:whole]
    return unless whole.match?(/\A\d*\z/) || grouped?(whole)

    [ whole.delete(".,").presence || "0", match[:cents].ljust(2, "0").to_i ]
  end

  # @return [Array(String, Integer), nil]
  def self.whole_euros(digits)
    return [ digits, 0 ] if digits.match?(/\A\d+\z/)
    return [ digits.delete(".,"), 0 ] if grouped?(digits) && digits.count(".,") > 1

    nil
  end

  def self.grouped?(text)
    text.match?(GROUPED) && text.delete("0-9").chars.uniq.one?
  end

  private_class_method :split_decimals, :whole_euros, :grouped?
end
