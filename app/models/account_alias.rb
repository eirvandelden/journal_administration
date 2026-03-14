# A pattern used to recognize transactions belonging to a given account
#
# Patterns are matched case-insensitively as substrings against merchant names
# from bank imports (e.g. "AH " matches "AH Amsterdam").
class AccountAlias < ApplicationRecord
  belongs_to :account

  validates :pattern, presence: true
  validates :pattern, uniqueness: { case_sensitive: false }
  validates :pattern, format: { without: /[%_]/, message: :invalid_like_characters }
  validate :account_must_be_external

  private

  def account_must_be_external
    return if account.blank? || account.external?

    errors.add(:account, :must_be_external)
  end
end
