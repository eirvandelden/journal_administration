module Importing
  module AlbertHeijn
    # Records the basket from an Albert Heijn basket mail
    #
    # A delivery is identified by its order number, so a slip that arrives twice
    # — Albert Heijn sends a fresh one whenever the order changes — updates the
    # delivery already recorded instead of adding a second one, and splits its
    # payment again so the books follow the corrected basket. Which payment
    # settled it is left to a person: empties are settled at the door, so the
    # amount the bank took rarely equals the slip's total.
    class ImportJob < ApplicationJob
      queue_as :default

      # @param mail [String] the basket mail as text
      # @return [void]
      def perform(mail)
        basket = BasketMail.parse(mail)
        return if basket.blank?

        Receipt.record_basket(basket)
      end
    end
  end
end
