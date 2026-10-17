require "test_helper"

class CentsTest < ActiveSupport::TestCase
  test "Cents.parse reads 1,50 and 1.50 and 1,5 as 150" do
    assert_equal 150, Cents.parse("1,50")
    assert_equal 150, Cents.parse("1.50")
    assert_equal 150, Cents.parse("1,5")
    assert_equal 150, Cents.parse("1.5")
  end

  test "reads whole euros" do
    assert_equal 1200, Cents.parse("12")
    assert_equal 0, Cents.parse("0")
    assert_equal 5, Cents.parse("0,05")
  end

  test "reads thousands separators in both styles" do
    assert_equal 123_456, Cents.parse("1.234,56")
    assert_equal 123_456, Cents.parse("1,234.56")
    assert_equal 123_456_700, Cents.parse("1.234.567")
    assert_equal 123_456_700, Cents.parse("1,234,567")
  end

  test "reads a negative amount" do
    assert_equal(-320, Cents.parse("-3,20"))
    assert_equal(-1200, Cents.parse(" -12 "))
  end

  test "returns nil for text that is not an amount" do
    [ "abc", "", "  ", "1,2,3", "1.2345", "-", "1,", ",5", "€ 1,50" ].each do |text|
      assert_nil Cents.parse(text), "expected #{text.inspect} to be refused"
    end
    assert_nil Cents.parse(nil)
  end

  test "returns nil for a misplaced thousands separator" do
    assert_nil Cents.parse("12,34,56")
    assert_nil Cents.parse("1.23.456")
    assert_nil Cents.parse("12.345,6.7")
  end

  test "returns nil for an ambiguous 1.500 or 1,500" do
    assert_nil Cents.parse("1.500")
    assert_nil Cents.parse("1,500")
  end

  test "Cents.from_euros converts a Float exactly" do
    assert_equal 1234, Cents.from_euros(12.34)
    assert_equal 1250, Cents.from_euros(12.5)
    assert_equal 1250, Cents.from_euros(BigDecimal("12.50"))
    assert_equal 1200, Cents.from_euros(12)
    assert_equal 29, Cents.from_euros(0.29)
  end

  test "refuses a fraction of a cent" do
    assert_raises(ArgumentError) { Cents.from_euros(12.345) }
  end

  test "Cents.to_euros returns BigDecimal euros" do
    assert_equal BigDecimal("12.5"), Cents.to_euros(1250)
    assert_kind_of BigDecimal, Cents.to_euros(1250)
    assert_equal BigDecimal("-0.05"), Cents.to_euros(-5)
  end

  test "keeps nil" do
    assert_nil Cents.to_euros(nil)
  end
end
