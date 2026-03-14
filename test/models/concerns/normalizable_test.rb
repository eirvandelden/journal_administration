require "test_helper"

class NormalizableTest < ActiveSupport::TestCase
  test "find_or_create_with_normalized_name finds by alias" do
    account = Account.find_or_create_with_normalized_name("AH Amsterdam")

    assert_equal accounts(:albert_heijn), account
  end

  test "find_or_create_with_normalized_name creates new account when no alias matches" do
    account = Account.find_or_create_with_normalized_name("Some Unknown Store")

    assert_equal "Some Unknown Store", account.name
  end
end
