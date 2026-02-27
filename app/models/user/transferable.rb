# Adds signed transfer links for user account handoff.
module User::Transferable
  extend ActiveSupport::Concern

  TRANSFER_LINK_EXPIRY_DURATION = 4.hours

  class_methods do
    # Resolves a user from a signed transfer identifier.
    #
    # @param id [String]
    # @return [User, nil]
    def find_by_transfer_id(id)
      find_signed(id, purpose: :transfer)
    end
  end

  # Returns a signed transfer identifier for this user.
  #
  # @return [String]
  def transfer_id
    signed_id(purpose: :transfer, expires_in: TRANSFER_LINK_EXPIRY_DURATION)
  end
end
