# Provides predicates for checking if accounts are family-owned, and moves a counterparty
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

  # Replaces one account on this transaction with another and saves it
  #
  # The category follows the account only when it is still the old account's default and the
  # transaction has no explicit splits: anything chosen by hand, and every split, stays.
  #
  # @param from [Account] The account the transaction is booked on now
  # @param to [Account] The account to book it on instead
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] If the transaction no longer validates
  def move_counterparty(from:, to:)
    self.category = to.category if follows_default_category_of?(from)
    self.debitor = to if debitor == from
    self.creditor = to if creditor == from
    save!
  end

  private

  def follows_default_category_of?(account)
    category_id == account.category_id && !split?
  end
end
