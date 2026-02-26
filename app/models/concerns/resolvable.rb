# Resolves counterparty accounts during CSV imports
#
# Implements a smart account resolution strategy: first by account number,
# then by matching against known family accounts, finally by normalized name lookup.
module Resolvable
  extend ActiveSupport::Concern

  class_methods do
    # Resolves or creates an account from import data
    #
    # Uses a cascade strategy:
    # 1. Find by explicit account_number if provided
    # 2. Match account_number embedded in transaction description
    # 3. Create or find by normalized merchant name
    #
    # @param account_number [String, nil] The account number if known
    # @param description [String] The transaction description that may contain an account number
    # @param name [String] The merchant/counterparty name
    # @return [Account] An existing or newly created account
    def resolve_for_import(account_number:, description:, name:)
      if account_number.present?
        return find_or_create_by(account_number: account_number)
      end

      account = resolve_from_description(description)
      return account if account.present?

      find_or_create_with_normalized_name(name)
    end

    # Attempts to find a family account embedded in transaction description
    #
    # Searches the description for any family account number and returns that account.
    # Used for detecting transfers between family accounts.
    #
    # @param description [String] The transaction description
    # @return [Account, nil] The matched family account, or nil if no match
    def resolve_from_description(description)
      return if description.blank?

      matched_account = family_account_numbers.find { |account| description.include?(account) }
      find_by(account_number: matched_account) if matched_account.present?
    end

    private

    def family_account_numbers
      @family_account_numbers ||= where.not(owner: nil).where.not(account_number: [ nil, "" ]).pluck(:account_number)
    end
  end
end
