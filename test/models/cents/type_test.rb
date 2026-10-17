require "test_helper"

class Cents::TypeTest < ActiveSupport::TestCase
  setup { @type = Cents::Type.new }

  test "casts euro text to cents" do
    assert_equal 150, @type.cast("1,50")
    assert_equal 150, @type.cast("1.5")
  end

  test "keeps an Integer" do
    assert_equal 150, @type.cast(150)
    assert_equal 150, @type.serialize(150)
    assert_equal 150, @type.deserialize(150)
  end

  test "casts blank to nil" do
    assert_nil @type.cast(nil)
    assert_nil @type.cast("")
    assert_nil @type.cast("  ")
  end

  test "casts unreadable text to nil" do
    assert_nil @type.cast("abc")
  end

  test "refuses a Float or BigDecimal" do
    assert_raises(ArgumentError) { @type.cast(12.0) }
    assert_raises(ArgumentError) { @type.cast(BigDecimal("12.5")) }
  end

  test "reports an integer type" do
    assert_equal :integer, @type.type
  end
end
