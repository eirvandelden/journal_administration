module Importing
  module AlbertHeijn
    # One Albert Heijn packing slip mail: what was actually packed for a delivery
    #
    # Albert Heijn never mails the invoice itself, so this slip is the closest
    # record of a delivery. Its bonuses are listed apart from the products, each
    # naming the product it came off, and are folded back in here.
    class PackingSlip
      # One product on the slip, and the bonus taken off it
      Line = Struct.new(:name, :quantity, :full_amount, :discount_amount) do
        def paid_amount = full_amount - discount_amount
      end

      DELIVERY_DATE = /(\d{1,2})\s+(\p{L}+)\s+(\d{4})/
      ORDER_NUMBER = /Bestelnummer:\s*(\d+)/
      # Every heading this reader steers by; without one of them it is not a slip
      HEADINGS = [ "Aantal", "Boodschappen totaal", "Totaal" ].freeze
      FIELDS_PER_PRODUCT = 4

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      # Reads a packing slip mail, or nothing when the mail is not one
      #
      # @param mail [String] the mail as text
      # @return [PackingSlip, nil]
      def self.parse(mail)
        blocks = mail.split("\n\n").map(&:strip).reject(&:empty?)
        return nil unless readable?(blocks)

        new(blocks)
      end

      def self.readable?(blocks)
        blocks.grep(ORDER_NUMBER).any? &&
          blocks.grep(/Bezorging op/).any? &&
          HEADINGS.all? { |heading| blocks.include?(heading) } &&
          products_line_up?(blocks)
      end
      private_class_method :readable?

      # Each product is written as four blocks: what it is, how many, the price
      # each, and the price together. Anything else is not a slip we can read.
      def self.products_line_up?(blocks)
        (product_section(blocks).size % FIELDS_PER_PRODUCT).zero?
      end
      private_class_method :products_line_up?

      # The blocks that describe the products packed, without the free extras
      # Albert Heijn throws in. Read both while checking a mail and while
      # parsing one.
      def self.product_section(blocks)
        first = blocks.index("Aantal") + 3
        last = [ blocks.index("Gratis toegevoegd"), blocks.index("Boodschappen totaal") ].compact.min

        blocks[first...last]
      end

      def initialize(blocks)
        @blocks = blocks
        @order_number = blocks.grep(ORDER_NUMBER).first[ORDER_NUMBER, 1]
        @delivered_on = read_delivery_date
        @total_amount = amount_after(blocks.rindex("Totaal"))
        @lines = read_lines
      end

      private

      def read_delivery_date
        day, month, year = @blocks.grep(/Bezorging op/).first.match(DELIVERY_DATE).captures

        Date.new(year.to_i, dutch_months.index(month.downcase) + 1, day.to_i)
      end

      def dutch_months
        I18n.t("date.month_names", locale: :nl).compact.map(&:downcase)
      end

      def amount_after(index)
        BigDecimal(@blocks[index + 1])
      end

      def read_lines
        products.each_slice(FIELDS_PER_PRODUCT).map do |name, quantity, _shelf_price, total|
          Line.new(name, quantity.to_i, BigDecimal(total), discounts.fetch(name, 0))
        end
      end

      # The products packed, without the free extras Albert Heijn throws in
      def products
        self.class.product_section(@blocks)
      end

      # A product can be discounted more than once on one slip — two promotions on
      # the same thing — so the bonuses on a name are added up, not overwritten.
      # The slip writes a bonus as a negative amount; a discount is recorded as
      # the size of what came off, whichever sign the slip used.
      def discounts
        @discounts ||= bonuses.each_slice(3).each_with_object(Hash.new(0)) do |(name, _promotion, amount), all|
          all[name] += BigDecimal(amount).abs
        end
      end

      # Empty on a delivery where nothing was on bonus: the summary still names
      # the bonus row, but no detail section follows it.
      def bonuses
        first = @blocks.rindex("Bonusvoordeel")
        last = @blocks.index("Totaal voordeel")
        return [] if first.nil? || last.nil? || last < first

        @blocks[(first + 1)...last]
      end
    end
  end
end
