class MakeAccountAliasPatternsGloballyUnique < ActiveRecord::Migration[8.0]
  def change
    duplicate_patterns = select_values(<<~SQL.squish)
      SELECT LOWER(pattern)
      FROM account_aliases
      GROUP BY LOWER(pattern)
      HAVING COUNT(*) > 1
    SQL

    raise "Duplicate account alias patterns found: #{duplicate_patterns.join(', ')}" if duplicate_patterns.any?

    add_index :account_aliases, "LOWER(pattern)", unique: true, name: "index_account_aliases_on_lower_pattern"
  end
end
