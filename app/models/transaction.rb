# Represents a double-entry journal entry.
#
# A transaction owns two or more mutations whose signed amounts must sum to zero.
class Transaction < ApplicationRecord
  include Categorizable
  include Importable
  include Linkable

  scope :ordered, -> { order(booked_at: :desc) }
  scope :for_index, -> { includes(:category, mutations: :account).order(interest_at: :desc) }
  scope :with_external_accounts, -> { joins(mutations: :account).where(accounts: { owner: nil }).distinct }
  scope :transfers, -> { where.not(id: with_external_accounts.select(:id)) }

  has_many :mutations, foreign_key: :transaction_id, inverse_of: :journal_entry, dependent: :destroy
  belongs_to :category, optional: true
  has_many :chattels, foreign_key: :purchase_transaction_id, dependent: :restrict_with_error

  before_validation :assign_transfer_category_for_new_internal_transfer

  validates :booked_at, presence: true
  validates_associated :mutations
  validate :internal_transfers_keep_transfer_category
  validate :mutations_sum_to_zero

  # Returns the account that receives money (positive mutation).
  #
  # @return [Account, nil]
  def creditor
    mutations.find { |mutation| mutation.amount.to_d.positive? }&.account
  end

  # Returns the account that sends money (negative mutation).
  #
  # @return [Account, nil]
  def debitor
    mutations.find { |mutation| mutation.amount.to_d.negative? }&.account
  end

  # Returns the absolute transaction amount as the sum of positive mutations.
  #
  # @return [BigDecimal]
  def amount
    mutations.sum { |mutation| mutation.amount.to_d.positive? ? mutation.amount.to_d : 0 }
  end

  # Returns whether this transaction is an internal transfer between family accounts.
  #
  # @return [Boolean]
  def transfer?
    mutations.any? && mutations.all? { |mutation| mutation.account&.owner.present? }
  end

  # Returns whether the transfer category should stay locked in the form.
  #
  # @return [Boolean]
  def transfer_category_locked?
    transfer? && category == transfer_category
  end

  # Returns an icon that indicates transfer, incoming, or outgoing flow.
  #
  # @return [String]
  def type_icon
    if transfer?
      "🔄 ◻️"  # Transfer
    elsif mutations.any? { |m| m.amount.to_d.positive? && m.account&.owner.present? }
      "⬇️ 🟥"  # Credit
    else
      "⬆️ 🟩"  # Debit
    end
  end

  # Returns mutations linked to family-owned accounts.
  #
  # @return [ActiveRecord::Relation<Mutation>]
  def our_mutations
    mutations.joins(:account).where.not(accounts: { owner: nil })
  end

  private

  def internal_transfers_keep_transfer_category
    return if new_record?
    return unless will_save_change_to_category_id?
    return unless transfer?
    return if category == transfer_category

    errors.add(:category, :must_remain_transfer)
  end

  def mutations_sum_to_zero
    if mutations.size < 2
      errors.add(:mutations, :too_short, count: 2)
      return
    end

    return if mutations.any? { |mutation| mutation.amount.nil? }

    return if mutations.sum { |mutation| mutation.amount.to_d }.zero?

    errors.add(:mutations, :invalid)
  end

  def transfer_category
    @transfer_category ||= Category.find_by(name: "Transfer")
  end

  def assign_transfer_category_for_new_internal_transfer
    return unless new_record?
    return unless transfer?
    return if category == transfer_category

    self.category = transfer_category
  end
end
