require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  # -- text column matching ---------------------------------------------------

  test "search returns records matching a text column" do
    results = Account.search("Gezamenlijke")

    assert_includes results, accounts(:checking)
    assert_not_includes results, accounts(:savings)
  end

  test "search is case-insensitive for ASCII" do
    results = Account.search("gezamenlijke")

    assert_includes results, accounts(:checking)
  end

  test "search matches partial strings" do
    results = Account.search("Gezamen")

    assert_includes results, accounts(:checking)
  end

  test "search matches across multiple declared columns" do
    results = Account.search("NL00INGB0123456789")

    assert_includes results, accounts(:savings)
  end

  # -- limit ------------------------------------------------------------------

  test "search returns at most 10 results" do
    11.times { |i| Account.create!(name: "SearchLimit #{i}") }

    results = Account.search("SearchLimit")

    assert_equal 10, results.count
  end

  # -- blank query ------------------------------------------------------------

  test "search returns none for empty string" do
    assert_equal 0, Account.search("").count
  end

  test "search returns none for nil" do
    assert_equal 0, Account.search(nil).count
  end

  test "search returns none for whitespace-only string" do
    assert_equal 0, Account.search("   ").count
  end
end
