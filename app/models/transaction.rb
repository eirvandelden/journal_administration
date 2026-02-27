# Represents a double-entry journal entry.
#
# A transaction owns two or more mutations whose signed amounts must sum to zero.
class Transaction < ApplicationRecord
  include Categorizable
  include Importable

  scope :ordered, -> { order(booked_at: :desc) }

  has_many :mutations, foreign_key: :transaction_id, inverse_of: :journal_entry, dependent: :destroy
  belongs_to :category, optional: true
  has_many :chattels, foreign_key: :purchase_transaction_id, dependent: :restrict_with_error

  validates :booked_at, presence: true
  validate  :mutations_sum_to_zero

  # Returns the account that receives money (positive mutation).
  #
  # @return [Account, nil]
  def creditor
    mutations.find { |m| m.amount > 0 }&.account
  end

  # Returns the account that sends money (negative mutation).
  #
  # @return [Account, nil]
  def debitor
    mutations.find { |m| m.amount < 0 }&.account
  end

  # Returns the absolute transaction amount as the sum of positive mutations.
  #
  # @return [BigDecimal]
  def amount
    mutations.map(&:amount).select(&:positive?).sum
  end

  # Returns an icon that indicates transfer, incoming, or outgoing flow.
  #
  # @return [String]
  def type_icon
    if mutations.all? { |m| m.account&.owner.present? }
      "🔄 ◻️"  # Transfer
    elsif mutations.any? { |m| m.amount > 0 && m.account&.owner.present? }
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

  # Enforces double-entry balance rules.
  #
  # @return [void]
  def mutations_sum_to_zero
    if mutations.size < 2
      errors.add(:mutations, :too_short, count: 2)
      return
    end

    return if mutations.map(&:amount).sum.zero?

    errors.add(:mutations, :invalid)
  end
end
