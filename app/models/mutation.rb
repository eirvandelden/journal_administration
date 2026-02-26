class Mutation < ApplicationRecord
  belongs_to :journal_entry, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :mutations
  belongs_to :account

  validates :amount, presence: true
end
