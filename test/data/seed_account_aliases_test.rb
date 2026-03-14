require "test_helper"
require_relative "../../db/data/20260315000002_seed_account_aliases"

class SeedAccountAliasesTest < ActiveSupport::TestCase
  test "creates the canonical account when it was renamed" do
    account = accounts(:albert_heijn)
    account.account_aliases.destroy_all
    account.update!(name: "Albert Heijn Renamed")

    SeedAccountAliases.new.up

    account = Account.find_by!(name: "Albert Heijn B.V.")

    assert_equal [ "AH ", "AH to go", "Albert Heijn" ], account.account_aliases.order(:pattern).pluck(:pattern)
  end
end
