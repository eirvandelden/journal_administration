# Folds duplicate external accounts into this one
#
# One shop can show up as several accounts, for example when its bank numbers differ. The
# account that merges survives. Its name stays. The duplicates' transactions, receipts, aliases
# and numbers move to it, then the emptied duplicates go away. A merge is final.
#
# Moving uses `update_all`, as `absorb_transactions_from_aliases` does: no callbacks run and
# `updated_at` stays. Transaction types stay right because only external accounts merge.
module Mergeable
  extend ActiveSupport::Concern

  # Merges the duplicates into this account
  #
  # @param duplicates [Array<Account>] Accounts to fold into this one
  # @return [Boolean] true when merged; false with errors on :base when refused, nothing changed
  def merge(duplicates)
    duplicates = Array(duplicates)
    return false unless mergeable_with?(duplicates)

    transaction { absorb(duplicates) }
    reset_merged_associations
    true
  end

  # @return [Integer] Transactions that have this account on either side
  def transactions_count
    Transaction.by_account(id).count
  end

  # @return [Integer] Receipts bought at this account
  def receipts_count
    receipts.count
  end

  private

  def mergeable_with?(duplicates)
    refusals = merge_refusals(duplicates)
    refusals.each { |reason| errors.add(:base, reason) }
    refusals.empty?
  end

  def merge_refusals(duplicates)
    return [ :merge_nothing_picked ] if duplicates.empty?

    [].tap do |refusals|
      refusals << :merge_into_household unless external?
      refusals << :merge_household_duplicate unless duplicates.all?(&:external?)
      refusals << :merge_into_itself if duplicates.include?(self)
      refusals << :merge_provider_into_shop if duplicates.any?(&:payment_provider?) && !payment_provider?
    end
  end

  def absorb(duplicates)
    ids = duplicates.map(&:id)
    move_records_of(ids)
    update!(category: first_category_of(duplicates)) if category.nil?
    Account.where(id: ids).find_each(&:destroy!)
  end

  def move_records_of(ids)
    Transaction.where(debitor_account_id: ids).update_all(debitor_account_id: id)
    Transaction.where(creditor_account_id: ids).update_all(creditor_account_id: id)
    Receipt.where(shop_id: ids).update_all(shop_id: id)
    AccountAlias.where(account_id: ids).update_all(account_id: id)
    AccountNumber.where(account_id: ids).update_all(account_id: id)
  end

  def first_category_of(duplicates)
    duplicates.sort_by(&:id).filter_map(&:category).first
  end

  def reset_merged_associations
    account_numbers.reset
    account_aliases.reset
    receipts.reset
  end
end
