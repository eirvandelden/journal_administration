module Importing
  module AlbertHeijn
    # One older Albert Heijn "Alsjeblieft, hier is jouw digitale pakbon" mail
    #
    # The same facts as a current packing slip, written in another layout: the order number
    # sits in one line, and the bonuses follow the subtotal.
    class OlderPackingSlip
      include Reading

      ORDER_NUMBER = /\AJouw bestelling:\s*(\d+)\z/
      DELIVERY_LINE = /\AOp \p{L}+ \d{1,2} \p{L}+ \d{4}/
      TABLE_HEADING = [ "Prijs per stuk", "Totaal" ].freeze

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      # Reads an older packing slip mail, or nothing when the mail is not one
      #
      #: (String mail) -> OlderPackingSlip?
      def self.parse(mail)
        tokens = Reading.tokens(mail)
        slip = new(tokens) if readable?(tokens)
        slip if slip&.reconciles?
      end

      def self.readable?(tokens)
        tokens.grep(ORDER_NUMBER).any? && tokens.grep(DELIVERY_LINE).any? &&
          tokens.include?("Kostenoverzicht") && tokens.include?("Subtotaal boodschappen") &&
          tokens.include?("Totaal*")
      end
      private_class_method :readable?

      def initialize(tokens)
        @tokens = tokens
        @order_number = tokens.grep(ORDER_NUMBER).first[ORDER_NUMBER, 1]
        @delivered_on = date_in(tokens.grep(DELIVERY_LINE).first)
        @total_amount = amount_after(tokens, tokens.rindex("Totaal*"))
        @lines = lines_from(products, discounts_in(tokens))
      end

      #: () -> bool
      def packed? = true

      private

      def shelf_amount = stated("Subtotaal boodschappen")

      def settled_amount = stated("Subtotaal")

      def products
        first = @tokens.index("Prijs per stuk") + TABLE_HEADING.size
        section_between(@tokens, first, "Gratis bij je bestelling", "Subtotaal boodschappen")
      end
    end
  end
end
