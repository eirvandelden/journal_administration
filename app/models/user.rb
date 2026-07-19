class User < ApplicationRecord
  include Role, Appkit::Transferable, Appkit::UserTheming

  has_many :sessions, dependent: :destroy
  has_many :push_subscriptions, class_name: "Appkit::PushSubscription", dependent: :destroy

  # Not Appkit::Authenticatable: it calls `has_secure_password` without
  # `validations: false`, which would add stricter password validations JA
  # never had (user creation/validation is owned by the admin panel).
  has_secure_password validations: false

  validates :name, presence: true, uniqueness: true
  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true
  validates :locale, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  enum :locale, { nl: 0, en: 1, it: 2 }

  def current?
    self == Current.user
  end

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
