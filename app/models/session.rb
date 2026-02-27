# Represents an authenticated browser session.
class Session < ApplicationRecord
  ACTIVITY_REFRESH_RATE = 1.hour

  has_secure_token

  belongs_to :user

  validates :token, presence: true, uniqueness: true
  validates :last_active_at, presence: true

  before_validation { self.last_active_at ||= Time.now }

  # Creates a new session for the given request metadata.
  #
  # @param user_agent [String, nil]
  # @param ip_address [String, nil]
  # @return [Session]
  def self.start!(user_agent:, ip_address:)
    create! user_agent: user_agent, ip_address: ip_address
  end

  # Refreshes activity fields when the refresh interval has passed.
  #
  # @param user_agent [String, nil]
  # @param ip_address [String, nil]
  # @return [void]
  def resume(user_agent:, ip_address:)
    if last_active_at.before?(ACTIVITY_REFRESH_RATE.ago)
      update! user_agent: user_agent, ip_address: ip_address, last_active_at: Time.now
    end
  end
end
