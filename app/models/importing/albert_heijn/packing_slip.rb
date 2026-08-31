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

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      # Reads a packing slip mail, or nothing when the mail is not one
      #
      # @param mail [String] the mail as text
      # @return [PackingSlip, nil]
      def self.parse(mail)
        blocks = mail.split("\n\n").map(&:strip).reject(&:empty?)
        return nil unless blocks.grep(ORDER_NUMBER).any? && blocks.include?("Boodschappen totaal")

        new(blocks)
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
        products.each_slice(4).map do |name, quantity, _shelf_price, total|
          Line.new(name, quantity.to_i, BigDecimal(total), discounts.fetch(name, 0))
        end
      end

      # The products packed, without the free extras Albert Heijn throws in
      def products
        first = @blocks.index("Aantal") + 3
        last = [ @blocks.index("Gratis toegevoegd"), @blocks.index("Boodschappen totaal") ].compact.min

        @blocks[first...last]
      end

      def discounts
        @discounts ||= bonuses.each_slice(3).to_h { |name, _promotion, amount| [ name, -BigDecimal(amount) ] }
      end

      def bonuses
        @blocks[(@blocks.rindex("Bonusvoordeel") + 1)...@blocks.index("Totaal voordeel")]
      end
    end
  end
end
