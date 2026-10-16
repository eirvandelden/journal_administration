# Provides predicates for checking whether accounts have household owners, and moves a counterparty
#
# Used by Transaction to determine transaction type and validate account relationships.
module Accountable
  extend ActiveSupport::Concern

  # Checks whether the debitor account has a household owner.
  #
  # @return [Boolean] True when the debitor has a household owner.
  def debitor_is_us?
    debitor&.household_owned?
  end

  # Checks whether the creditor account has a household owner.
  #
  # @return [Boolean] True when the creditor has a household owner.
  def creditor_is_us?
    creditor&.household_owned?
  end

  # Checks whether both accounts have household owners.
  #
  # @return [Boolean] True when both accounts have household owners.
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
