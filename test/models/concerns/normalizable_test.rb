require "test_helper"

class NormalizableTest < ActiveSupport::TestCase
  test "normalizes Albert Heijn variations" do
    assert_equal "Albert Heijn B.V.", Account.normalize("AH Amsterdam")
    assert_equal "Albert Heijn B.V.", Account.normalize("AH to go Utrecht")
    assert_equal "Albert Heijn B.V.", Account.normalize("Albert Heijn")
    assert_equal "Albert Heijn B.V.", Account.normalize("ALBERT HEIJN BV")
  end

  test "normalizes Jumbo" do
    assert_equal "Jumbo B.V.", Account.normalize("Jumbo Amsterdam")
  end

  test "normalizes Kruidvat variations" do
    assert_equal "Kruidvat B.V.", Account.normalize("Kruidvat Centrum")
    assert_equal "Kruidvat B.V.", Account.normalize("KRUIDVAT BV")
  end

  test "returns original name when no match" do
    assert_equal "Some Store", Account.normalize("Some Store")
  end

  test "find_or_create_with_normalized_name normalizes before lookup" do
    account = Account.find_or_create_with_normalized_name("AH Amsterdam")

    assert_equal "Albert Heijn B.V.", account.name
  end
end
