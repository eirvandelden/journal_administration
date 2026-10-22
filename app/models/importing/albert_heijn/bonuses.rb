module Importing
  module AlbertHeijn
    # The bonus section of an Albert Heijn mail: what came off each product named in it
    #
    # A product is named once, followed by one promotion and amount for each bonus it earned. A
    # promotion and amount can come without a name when the same product earned a second bonus, so
    # they belong to the product above. An amount of nothing is ignored. Older confirmations list a
    # name, an amount and then the promotion instead.
    class Bonuses
      AMOUNT = /\A-?\d+\.\d{2}\z/
      FIELDS_PER_ENTRY = 3

      # @param entries [Array<String>] the lines between the "Bonusvoordeel" heading and "Totaal voordeel"
      def initialize(entries)
        @entries = entries
      end

      # The size of what came off each named product, added up when it earned several bonuses
      #
      #: () -> Hash[String, Integer]
      def by_product
        amount_second? ? name_amount_promotion : name_promotion_amount
      end

      private

      def amount_second? = amount?(@entries[1])

      def amount?(text) = text.to_s.match?(AMOUNT)

      def name_amount_promotion
        @entries.each_slice(FIELDS_PER_ENTRY).each_with_object(Hash.new(0)) do |(name, amount), taken|
          taken[name] += cents(amount)
        end
      end

      def cents(text) = Cents.from_euros(BigDecimal(text).abs)

      def name_promotion_amount
        name = nil
        (@entries + [ nil ]).each_cons(2).each_with_object(Hash.new(0)) do |(entry, following), taken|
          if amount?(following) then taken[name] += cents(following) if name
          elsif !amount?(entry) then name = entry
          end
        end
      end
    end
  end
end
