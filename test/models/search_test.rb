require "test_helper"

class SearchTest < ActiveSupport::TestCase
  # -- blank query ------------------------------------------------------------

  test "results returns empty hash for blank query" do
    search = Search.new(query: "")

    assert_equal({}, search.results)
  end

  test "results returns empty hash for whitespace-only query" do
    search = Search.new(query: "   ")

    assert_equal({}, search.results)
  end

  test "any_results? returns false for blank query" do
    search = Search.new(query: "")

    assert_not search.any_results?
  end

  # -- account results --------------------------------------------------------

  test "results includes accounts matching by name" do
    search = Search.new(query: "Gezamenlijke")

    assert_includes search.results[:accounts], accounts(:checking)
  end

  test "results includes accounts matching by account_number" do
    search = Search.new(query: "NL00INGB0123456789")

    assert_includes search.results[:accounts], accounts(:savings)
  end

  # -- transaction results ----------------------------------------------------

  test "results includes transactions matching by note" do
    search = Search.new(query: "Groceries at AH")

    assert_includes search.results[:transactions], transactions(:debit_grocery)
  end

  test "results includes transactions matching by amount" do
    search = Search.new(query: "3000")

    assert_includes search.results[:transactions], transactions(:credit_salary)
  end

  # -- chattel results --------------------------------------------------------

  test "results includes chattels matching by name" do
    search = Search.new(query: "Laptop")

    assert_includes search.results[:chattels], chattels(:one)
  end

  test "results includes chattels matching by model_number" do
    search = Search.new(query: "XPS-15")

    assert_includes search.results[:chattels], chattels(:one)
  end

  # -- category results -------------------------------------------------------

  test "results includes categories matching by name" do
    search = Search.new(query: "Salary")

    assert_includes search.results[:categories], categories(:salary)
  end

  # -- page results -----------------------------------------------------------

  test "results includes pages matching nav labels" do
    # "Thuis" is the home label in the en locale
    search = Search.new(query: "Thuis")

    assert search.results.key?(:pages)
  end

  # -- empty groups -----------------------------------------------------------

  test "results omits groups with no matches" do
    search = Search.new(query: "xyzzy_nonexistent_42")

    assert_equal({}, search.results)
  end

  test "results omits groups that are empty" do
    search = Search.new(query: "Laptop")

    assert_not search.results.key?(:pages)
    assert_not search.results.key?(:transactions)
  end

  # -- any_results? -----------------------------------------------------------

  test "any_results? returns true when there are matching records" do
    search = Search.new(query: "Laptop")

    assert search.any_results?
  end

  # -- memoization ------------------------------------------------------------

  test "results are memoized" do
    search = Search.new(query: "Salary")

    assert_same search.results, search.results
  end
end
