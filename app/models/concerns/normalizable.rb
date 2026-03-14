# Resolves merchant names from bank exports to canonical accounts via configurable aliases
#
# Aliases are stored in the account_aliases table and matched case-insensitively
# as substrings against the merchant name (e.g. pattern "AH " matches "AH Amsterdam").
module Normalizable
  extend ActiveSupport::Concern

  class_methods do
    # Finds an account whose alias pattern is contained in the given name (case-insensitive),
    # or creates a new account with that name if no alias matches.
    #
    # @param name [String] Raw merchant name from CSV export
    # @return [Account] Matched existing account, or newly created account with that name
    def find_or_create_with_normalized_name(name)
      find_by_alias(name) || find_or_create_by(name: name)
    end

    # Finds an account whose alias pattern appears in the given name (case-insensitive)
    #
    # @param name [String] Raw merchant name
    # @return [Account, nil] Matching account, or nil if no alias matches
    def find_by_alias(name)
      joins(:account_aliases)
        .find_by("LOWER(?) LIKE '%' || LOWER(account_aliases.pattern) || '%'", name)
    end
  end
end
