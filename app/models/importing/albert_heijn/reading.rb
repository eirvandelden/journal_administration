module Importing
  module AlbertHeijn
    # What the Albert Heijn mail readers share: the mail as a list of lines, Dutch dates, amounts,
    # and the rows of a product table
    #
    # A product is four lines — name, quantity, price each, price together. Headings inside a table are
    # not a product, so they are stepped over. The bonuses are read by `Bonuses`.
    module Reading
      FIELDS_PER_PRODUCT = 4
      DELIVERY_DATE = /(\d{1,2})\s+(\p{L}+)\s+(\d{4})/
      AMOUNT = /\A\d+\.\d{2}\z/
      PRICE_EACH = /\A(\d+\.\d{2}|gew\.)\z/
      DEPOSIT_ROW = /\A\+ Statiegeld/

      # @param mail [String] the mail as text
      # @return [Array<String>] every line of the mail with something on it, without its padding
      def self.tokens(mail)
        mail.lines.map(&:strip).reject(&:empty?)
      end

      # Whether what the mail lists adds up to what it states
      #
      # The lines make the shelf total, and the shelf total less the bonus makes what is settled before
      # the extras. A mail that does not add up was misread or cut off, so it is not a basket.
      #
      #: () -> bool
      def reconciles?
        lines.sum(&:full_amount) + deposit_amount == shelf_amount && shelf_amount - bonus_amount == settled_amount
      end

      private

      def stated(heading)
        index = @tokens.index(heading)
        amount_after(@tokens, index) if index
      end

      def bonus_amount = stated("Totaal voordeel")&.abs || 0

      # A deposit row sits among the products of an older confirmation, but is no product
      def deposit_amount = product_rows(products).select { |row| deposit_row?(row) }.sum { |row| cents(row.last) }

      def deposit_row?(row) = row.first.match?(DEPOSIT_ROW)

      def date_in(text)
        day, month, year = text.match(DELIVERY_DATE).captures
        month_number = dutch_months.index(month.downcase)
        raise ArgumentError, "unknown month #{month}" if month_number.nil?

        Date.new(year.to_i, month_number + 1, day.to_i)
      end

      def dutch_months
        I18n.t("date.month_names", locale: :nl).compact.map(&:downcase)
      end

      def cents(text) = Cents.from_euros(BigDecimal(text))

      # The amount a heading introduces, stepping over a note in brackets and a euro sign
      def amount_after(tokens, index)
        text = tokens.drop(index + 1).find { |token| !token.start_with?("(") }
        cents(text.to_s.delete_prefix("€").strip)
      end

      def lines_from(section, discounts)
        rows = product_rows(section).reject { |row| deposit_row?(row) }
        rows.map do |name, quantity, _price_each, total|
          PackingSlip::Line.new(name, quantity.to_i, cents(total), discounts.fetch(name, 0))
        end
      end

      def product_rows(section)
        section.each_index.filter_map { |index| section[index, FIELDS_PER_PRODUCT] if product_at?(section, index) }
      end

      def product_at?(section, index)
        section[index + 1].to_s.match?(/\A\d+\z/) &&
          section[index + 2].to_s.match?(PRICE_EACH) &&
          section[index + 3].to_s.match?(AMOUNT)
      end

      # A product can be discounted more than once in one mail, so the bonuses on a name are added
      # up. A discount is recorded as the size of what came off, whichever sign the mail used.
      def discounts_in(tokens)
        last = tokens.index("Totaal voordeel")
        first = last && tokens[0...last].rindex("Bonusvoordeel")
        return {} if first.nil?

        Bonuses.new(tokens[(first + 1)...last]).by_product
      end

      # The tokens from the product table's first row up to the first of these ends, or the rest
      def section_between(tokens, first, *ends)
        last = ends.filter_map { |ending| tokens.index(ending) }.min
        tokens[first...last]
      end
    end
  end
end
