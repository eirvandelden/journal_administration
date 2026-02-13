# Provides predicates for checking if accounts are family-owned
#
# Used by Transaction to determine transaction type and validate account relationships.
module Accountable
  extend ActiveSupport::Concern

  # Checks if the debitor account is a family-owned account
  #
  # @return [Boolean] True if debitor is one of the family owners
  def debitor_is_us?
    debitor&.owner&.in? Account::FAMILY_OWNERS
  end

  # Checks if the creditor account is a family-owned account
  #
  # @return [Boolean] True if creditor is one of the family owners
  def creditor_is_us?
    creditor&.owner&.in? Account::FAMILY_OWNERS
  end

  # Checks if both accounts are family-owned
  #
  # @return [Boolean] True if both debitor and creditor are family owners
  def both_accounts_are_ours?
    debitor_is_us? && creditor_is_us?
  end
end
