module Importing
  module AlbertHeijn
    # One Albert Heijn order confirmation mail, sent when an order is placed
    #
    # It lists what was ordered, not what was packed, so it stands in for a packing slip only
    # until one arrives. Its delivery date is the day planned.
    class OrderConfirmation
      include Reading

      ORDER_NUMBER = /\ABestelnummer:\s*(\d+)\z/
      DELIVERY_LINE = /\ABezorging op \p{L}+ \d{1,2} \p{L}+ \d{4}/
      GREETING = /\ABedankt voor je bestelling/
      TABLE_HEADING = [ "Aantal", "Prijs", "Totaal" ].freeze

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      # Reads an order confirmation mail, or nothing when the mail is not one
      #
      #: (String mail) -> OrderConfirmation?
      def self.parse(mail)
        tokens = Reading.tokens(mail)
        new(tokens) if readable?(tokens)
      end

      def self.readable?(tokens)
        tokens.grep(GREETING).any? && tokens.grep(ORDER_NUMBER).any? &&
          tokens.grep(DELIVERY_LINE).any? && tokens.include?("Boodschappen totaal") &&
          tokens.include?("Totaal")
      end
      private_class_method :readable?

      def initialize(tokens)
        @tokens = tokens
        @order_number = tokens.grep(ORDER_NUMBER).first[ORDER_NUMBER, 1]
        @delivered_on = date_in(tokens.grep(DELIVERY_LINE).first)
        @total_amount = amount_after(tokens, tokens.index("Totaal"))
        @lines = lines_from(products, discounts_in(tokens))
      end

      #: () -> bool
      def packed? = false

      private

      def products
        first = @tokens.rindex("Aantal") + TABLE_HEADING.size
        section_between(@tokens, first, "Gratis toegevoegd", "Boodschappen totaal")
      end
    end
  end
end
