module Importing
  module AlbertHeijn
    # The one way into the Albert Heijn mail readers
    #
    # Albert Heijn mails a basket in three layouts. A person or an assistant should not have to
    # know which one it holds, so this asks each reader in turn and gives back the first basket.
    module BasketMail
      READERS = [ PackingSlip, OlderPackingSlip, OrderConfirmation ].freeze

      # The basket the mail describes, or nothing when no reader understands it
      #
      # A mail a reader recognises but cannot finish reading — a month it does not know, an
      # amount that is not a number — is not a basket either, and neither is one with no lines.
      #
      #: (String text) -> (PackingSlip | OlderPackingSlip | OrderConfirmation)?
      def self.parse(text)
        basket = READERS.lazy.filter_map { |reader| reader.parse(text) }.first

        basket if basket&.lines&.any?
      rescue ArgumentError
        nil
      end
    end
  end
end
