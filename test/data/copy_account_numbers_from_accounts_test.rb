require "test_helper"
require_relative "../../db/data/20261016100000_copy_account_numbers_from_accounts"

class CopyAccountNumbersFromAccountsTest < ActiveSupport::TestCase
  setup do
    AccountNumber.delete_all
  end

  test "copies every non-blank number, normalized" do
    write_legacy_number(accounts(:jumbo), " nl00 abna 8888 888888 ")
    write_legacy_number(accounts(:savings), "NL00INGB0123456789")

    CopyAccountNumbersFromAccounts.new.up

    assert_equal %w[NL00ABNA8888888888], accounts(:jumbo).numbers
    assert_equal %w[NL00INGB0123456789], accounts(:savings).numbers
  end

  test "skips blank numbers" do
    write_legacy_number(accounts(:kruidvat), "   ")
    write_legacy_number(accounts(:unknown), "")
    write_legacy_number(accounts(:aon), nil)

    assert_no_difference "AccountNumber.count" do
      CopyAccountNumbersFromAccounts.new.up
    end
  end

  test "cannot be reversed" do
    assert_raises(ActiveRecord::IrreversibleMigration) { CopyAccountNumbersFromAccounts.new.down }
  end

  private

  # The column is ignored by Active Record, so the old data goes in through SQL.
  def write_legacy_number(account, number)
    Account.connection.update(
      Account.sanitize_sql([ "UPDATE accounts SET account_number = ? WHERE id = ?", number, account.id ])
    )
  end
end
