class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session

  # Return the first group-owned household account for family finances.
  attribute :account, default: -> { Account.own.where.not(group_id: nil).order(:id).first || Account.first }
end
