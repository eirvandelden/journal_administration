module Importing
  module AlbertHeijn
    # One Albert Heijn packing slip mail: what was actually packed for a delivery
    #
    # Albert Heijn never mails the invoice itself, so this slip is the closest
    # record of a delivery. Its bonuses are listed apart from the products, each
    # naming the product it came off, and are folded back in here.
    class PackingSlip
      include Reading

      # One product on the slip, and the bonus taken off it
      Line = Struct.new(:name, :quantity, :full_amount, :discount_amount) do
        def paid_amount = full_amount - discount_amount
      end

      ORDER_NUMBER = /Bestelnummer:\s*(\d+)/
      # Every heading this reader steers by; without one of them it is not a slip
      HEADINGS = [ "Aantal", "Boodschappen totaal", "Totaal" ].freeze
      TABLE_HEADING = [ "Aantal", "Prijs", "Totaal" ].freeze

      attr_reader :order_number, :delivered_on, :total_amount, :lines

      #: () -> bool
      def packed? = true

      # Reads a packing slip mail, or nothing when the mail is not one
      #
      # @param mail [String] the mail as text
      # @return [PackingSlip, nil]
      def self.parse(mail)
        blocks = mail.split("\n\n").map(&:strip).reject(&:empty?)
        return nil unless readable?(blocks)

        slip = new(blocks)
        slip if slip.reconciles?
      end

      def self.readable?(blocks)
        blocks.grep(ORDER_NUMBER).any? &&
          blocks.grep(/Bedankt voor je bestelling/).none? &&
          blocks.grep(/Bezorging op/).any? &&
          HEADINGS.all? { |heading| blocks.include?(heading) }
      end
      private_class_method :readable?

      def initialize(blocks)
        @tokens = blocks
        @order_number = blocks.grep(ORDER_NUMBER).first[ORDER_NUMBER, 1]
        @delivered_on = date_in(blocks.grep(/Bezorging op/).first)
        @total_amount = amount_after(blocks, blocks.rindex("Totaal"))
        @lines = lines_from(products, discounts_in(blocks))
      end

      private

      def shelf_amount = stated("Boodschappen totaal")

      def settled_amount = total_amount - (stated("Overig totaal") || 0)

      # The products packed, without the free extras Albert Heijn throws in. A section of products that
      # could not be delivered has a table of its own above this one, so the table that counts is the last.
      def products
        first = @tokens.rindex("Aantal") + TABLE_HEADING.size
        section_between(@tokens, first, "Gratis toegevoegd", "Boodschappen totaal")
      end
    end
  end
end
