class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def account
    return @account if defined?(@account)

    # Return the shared "samen" (together) account for family finances
    @account = Account.find_by(owner: :samen) || Account.first
  end
end
