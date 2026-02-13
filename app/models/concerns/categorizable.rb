# Provides automatic category assignment based on transaction type
#
# Different transaction types get categories from different sources:
# - Transfer: Uses the "Transfer" category
# - Credit: Uses debitor account's default category
# - Debit: Uses creditor account's default category
module Categorizable
  extend ActiveSupport::Concern

  # Assigns a category based on the transaction type and related accounts
  #
  # @return [void]
  def assign_category_from_type
    self.category = case type
                    when "Transfer"
                      Category.find_by(name: "Transfer")
                    when "Credit"
                      debitor&.category
                    when "Debit"
                      creditor&.category
                    end
  end
end
