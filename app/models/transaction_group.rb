class TransactionGroup < ApplicationRecord
  belongs_to :parent, class_name: "Transaction", foreign_key: "parent_id"
  belongs_to :related, class_name: "Transaction", foreign_key: "related_id"
end
