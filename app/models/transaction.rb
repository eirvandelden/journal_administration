# Transaction model holds all information for a trnansaction.
# The owner of the debitor account determins the type of Transaction: Debit or Credit.
# is debitor_account owned by us? This is a Debit Transaction!
# is creditor_account owned by us? This is a Credit Transaction!
# are both owned by the same owner? This is a Transfer Transaction!
class Transaction < ApplicationRecord
  belongs_to :debitor, class_name: 'Account', foreign_key: 'debitor_account_id'
  belongs_to :creditor, class_name: 'Account', foreign_key: 'creditor_account_id'
  belongs_to :category
end
