# Represents an authenticated application user.
class User < ApplicationRecord
  include Role, Transferable

  has_many :sessions, dependent: :destroy
  has_secure_password validations: false

  validates :name, presence: true, uniqueness: true
  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true
  validates :locale, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  enum :locale, { nl: 0, en: 1, it: 2 }

  # Indicates whether this user is the current request user.
  #
  # @return [Boolean]
  def current?
    self == Current.user
  end

  # Deactivates the user and expires all active sessions.
  #
  # @return [void]
  def deactivate
    transaction do
      sessions.delete_all
      update! active: false, email_address: deactivated_email_address
    end
  end

  private
    def deactivated_email_address
      email_address&.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end
end
