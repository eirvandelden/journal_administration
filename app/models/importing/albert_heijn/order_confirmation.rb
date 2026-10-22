module Importing
  module AlbertHeijn
    # One Albert Heijn order confirmation mail, sent when an order is placed
    #
    # It lists what was ordered, not what was packed, so it stands in for a packing slip only
    # until one arrives. Its delivery date is the day planned. Before mid 2023 the mail worded
    # its headings differently ("Bedankt voor jouw bestelling", "Totaal boodschappen") and
    # listed each bonus as a name, an amount and a promotion; both wordings are read here.
    class OrderConfirmation
      include Reading

      ORDER_NUMBER = /\A(?:Bestelnummer|Jouw bestelling):\s*(\d+)\z/
      DELIVERY_LINE = /\ABezorging op \p{L}+ \d{1,2} \p{L}+ \d{4}/
      GREETING = /\ABedankt voor (?:je|jouw) bestelling/
      SHELF_HEADINGS = [ "Boodschappen totaal", "Totaal boodschappen" ].freeze
      TABLE_HEADING = [ "Aantal", "Prijs", "Totaal" ].freeze

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      # Reads an order confirmation mail, or nothing when the mail is not one
      #
      #: (String mail) -> OrderConfirmation?
      def self.parse(mail)
        tokens = Reading.tokens(mail)
        confirmation = new(tokens) if readable?(tokens)
        confirmation if confirmation&.reconciles?
      end

      def self.readable?(tokens)
        tokens.grep(GREETING).any? && tokens.grep(ORDER_NUMBER).any? &&
          tokens.grep(DELIVERY_LINE).any? && (tokens & SHELF_HEADINGS).any? && tokens.include?("Totaal")
      end
      private_class_method :readable?

      def initialize(tokens)
        @tokens = tokens
        @shelf_heading = (tokens & SHELF_HEADINGS).first
        @order_number = tokens.grep(ORDER_NUMBER).first[ORDER_NUMBER, 1]
        @delivered_on = date_in(tokens.grep(DELIVERY_LINE).first)
        @total_amount = amount_after(tokens, tokens.index("Totaal"))
        @lines = lines_from(products, discounts_in(tokens))
      end

      #: () -> bool
      def packed? = false

      private

      def shelf_amount = stated(@shelf_heading)

      def settled_amount = total_amount - (stated("Overig totaal") || stated("Totaal servicekosten") || 0)

      def products
        first = @tokens.rindex("Aantal") + TABLE_HEADING.size
        section_between(@tokens, first, "Gratis toegevoegd", @shelf_heading)
      end
    end
  end
end
