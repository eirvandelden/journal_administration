class Transaction < ApplicationRecord
  include Categorizable
  include Importable

  scope :ordered, -> { order(booked_at: :desc) }

  has_many :mutations, foreign_key: :transaction_id, inverse_of: :journal_entry, dependent: :destroy
  belongs_to :category, optional: true
  has_many :chattels, foreign_key: :purchase_transaction_id, dependent: :restrict_with_error

  validates :booked_at, presence: true
  validate  :mutations_sum_to_zero

  # Returns the account that receives money (positive-amount mutation)
  def creditor
    mutations.find { |m| m.amount > 0 }&.account
  end

  # Returns the account that sends money (negative-amount mutation)
  def debitor
    mutations.find { |m| m.amount < 0 }&.account
  end

  # Returns the absolute transfer amount (sum of positive mutations)
  def amount
    mutations.map(&:amount).select(&:positive?).sum
  end

  # Returns an emoji representation of the transaction type derived from account ownership
  def type_icon
    if mutations.all? { |m| m.account&.owner.present? }
      "🔄 ◻️"  # Transfer
    elsif mutations.any? { |m| m.amount > 0 && m.account&.owner.present? }
      "⬇️ 🟥"  # Credit
    else
      "⬆️ 🟩"  # Debit
    end
  end

  # Returns mutations for family-owned accounts
  def our_mutations
    mutations.joins(:account).where.not(accounts: { owner: nil })
  end

  private

  def mutations_sum_to_zero
    if mutations.size < 2
      errors.add(:mutations, :too_short, count: 2)
      return
    end

    return if mutations.map(&:amount).sum.zero?

    errors.add(:mutations, :invalid)
  end
end
