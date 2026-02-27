# Stores request-scoped context shared across the app.
class Current < ActiveSupport::CurrentAttributes
  attribute :user

  # Return the shared "samen" (together) account for family finances
  attribute :account, default: -> { Account.find_by(owner: :samen) || Account.first }
end
