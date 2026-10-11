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
    # 1. Find by explicit account_number if provided; a shared payment provider hands over to
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
        return find_or_create_by(account_number: account_number).counterparty_for(description)
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
      resolve_by_account_number(description) || resolve_by_account_name(description)
    end

    # Finds a household account by its number embedded in a description.
    # @return [Account, nil]
    def resolve_by_account_number(description)
      match = own.where.not(account_number: nil).pluck(:account_number).find { |number| description.include?(number) }
      find_by(account_number: match) if match.present?
    end

    # Finds a household account by its name embedded in a description.
    # @return [Account, nil]
    def resolve_by_account_name(description)
      match = own.where.not(name: nil).pluck(:name).sort_by { |name| -name.length }
        .find { |name| description.include?(name) }
      find_by(name: match) if match.present?
    end
  end
end
