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
    # 1. Find by explicit account_number (any number of an account) if provided; a shared payment provider hands over to
    #    the merchant named in the description
    # 2. Match account_number embedded in transaction description
    # 3. Create or find by normalized merchant name
    #
    # @param account_number [String, nil] The account number if known
    # @param description [String] The transaction description that may contain an account number
    # @param name [String] The merchant/counterparty name
    # @return [Account] An existing or newly created account
    def resolve_for_import(account_number:, description:, name:)
      if account_number.present?
        return find_or_create_by_number(account_number).counterparty_for(description)
      end

      account = resolve_from_description(description)
      return account if account.present?

      find_or_create_with_normalized_name(name)
    end

    # Finds the account that owns a number, or creates an account holding it
    #
    # Spaces and case in the number do not matter. When a parallel import creates the same
    # number first, the unique index raises and this returns the account that won.
    #
    # @param number [String] An account number
    # @return [Account]
    def find_or_create_by_number(number)
      number = AccountNumber.normalize_value_for(:number, number)

      owner_of(number) || create!(account_numbers: [ AccountNumber.new(number:) ])
    rescue ActiveRecord::RecordNotUnique
      owner_of(number)
    end

    # Attempts to find a family account embedded in transaction description
    #
    # Searches the description for any family account number and returns that account.
    # Used for detecting transfers between family accounts.
    #
    # @param description [String] The transaction description
    # @return [Account, nil] The matched family account, or nil if no match
    def resolve_from_description(description)
      numbers = AccountNumber.where(account: own).pluck(:number)
      matched = numbers.find { |number| description.include?(number) }
      owner_of(matched) if matched.present?
    end

    private

    def owner_of(number)
      AccountNumber.find_by(number:)&.account
    end
  end
end
