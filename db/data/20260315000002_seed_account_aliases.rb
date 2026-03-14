# frozen_string_literal: true

class SeedAccountAliases < ActiveRecord::Migration[8.0]
  def up
    seed_aliases("Albert Heijn B.V.", [ "AH to go", "AH ", "Albert Heijn" ])
    seed_aliases("Jumbo B.V.", [ "Jumbo " ])
    seed_aliases("Kruidvat B.V.", [ "Kruidvat" ])
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def seed_aliases(account_name, patterns)
    account = Account.find_by(name: account_name)
    return unless account

    patterns.each do |pattern|
      account.account_aliases.find_or_create_by!(pattern: pattern)
    end
  end
end
