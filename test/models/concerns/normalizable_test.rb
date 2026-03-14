require "test_helper"

class NormalizableTest < ActiveSupport::TestCase
  test "find_or_create_with_normalized_name finds by alias" do
    account = Account.find_or_create_with_normalized_name("AH Amsterdam")

    assert_equal accounts(:albert_heijn), account
  end

  test "find_by_alias prefers the longest matching alias" do
    shorter_match = Account.create!(name: "Lidl")
    longer_match = Account.create!(name: "Lidl Online")

    shorter_match.account_aliases.create!(pattern: "Lidl")
    longer_match.account_aliases.create!(pattern: "Lidl Online")

    account = Account.find_by_alias("Lidl Online GmbH")

    assert_equal longer_match, account
  end

  test "find_or_create_with_normalized_name creates new account when no alias matches" do
    account = Account.find_or_create_with_normalized_name("Some Unknown Store")

    assert_equal "Some Unknown Store", account.name
  end
end
