# Provides merchant name normalization for bank accounts
#
# Maps variable merchant names from bank exports to canonical account names.
# For example, "AH to go" and "Albert Heijn" both normalize to "Albert Heijn B.V."
module Normalizable
  extend ActiveSupport::Concern

  class_methods do
    # Normalizes merchant names to canonical forms
    #
    # @param original_name [String] Raw merchant name from CSV export
    # @return [String] Canonical merchant name, or original if no mapping exists
    # @example
    #   Account.normalize("AH to go") # => "Albert Heijn B.V."
    def normalize(original_name)
      case original_name
      when /AH to go|AH |.*(Albert Heijn|ALBERT HEIJN|AH to go)/
        "Albert Heijn B.V."
      when /Jumbo /
        "Jumbo B.V."
      when /.*(Kruidvat|KRUIDVAT)/
        "Kruidvat B.V."
      else
        original_name
      end
    end

    # Finds or creates an account with a normalized name
    #
    # @param name [String] The merchant name (will be normalized)
    # @return [Account] Existing or newly created account with normalized name
    def find_or_create_with_normalized_name(name)
      normalized = normalize(name)
      find_or_create_by(name: normalized)
    end
  end
end
