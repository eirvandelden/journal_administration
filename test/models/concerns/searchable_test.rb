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

  # -- association columns ----------------------------------------------------

  test "search matches an association column" do
    results = Account.search("NL00ABNA9999999002")

    assert_includes results, accounts(:albert_heijn_duplicate)
    assert_not_includes results, accounts(:albert_heijn)
  end

  test "search matches a number typed with spaces and lowercase" do
    results = Account.search("nl00 abna 9999 9990 02")

    assert_includes results, accounts(:albert_heijn_duplicate)
  end

  test "search counts each record once when several numbers match" do
    results = Account.search("NL00ABNA99999990")

    assert_equal 1, results.where(id: accounts(:albert_heijn_duplicate)).count
    assert_equal 1, results.count { |account| account == accounts(:albert_heijn_duplicate) }
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
