module Categorizable
  extend ActiveSupport::Concern

  # Assigns a category based on the external account's default category.
  # Falls back to the "Transfer" category when both accounts are family-owned.
  #
  # @return [void]
  def assign_category_from_mutations
    mutation_list = mutations.to_a
    external_account = mutation_list.find { |m| m.account&.owner.nil? }&.account

    self.category = if external_account
      external_account.category
    else
      transfer_category
    end
  end

  private

  def transfer_category
    @transfer_category ||= Category.find_by(name: "Transfer")
  end
end
