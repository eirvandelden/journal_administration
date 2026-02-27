# Represents a signed posting line in a double-entry transaction.
#
# Each mutation links one account to one signed amount.
class Mutation < ApplicationRecord
  belongs_to :journal_entry, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :mutations
  belongs_to :account

  validates :amount, presence: true
end
