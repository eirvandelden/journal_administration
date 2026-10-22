# Copies accounts.account_number into account_numbers, normalized like AccountNumber does:
# trimmed, spaces removed, upper case. Blank numbers are skipped. Raw SQL, because Account
# ignores the old column.
class CopyAccountNumbersFromAccounts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO account_numbers (account_id, number, created_at, updated_at)
      SELECT id, UPPER(REPLACE(REPLACE(REPLACE(REPLACE(TRIM(account_number), ' ', ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
             CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM accounts
      WHERE account_number IS NOT NULL AND TRIM(account_number) <> ''
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
