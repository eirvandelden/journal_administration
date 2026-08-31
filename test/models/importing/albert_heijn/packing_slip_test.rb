require "test_helper"

class Importing::AlbertHeijn::PackingSlipTest < ActiveSupport::TestCase
  setup do
    @slip = Importing::AlbertHeijn::PackingSlip.parse(file_fixture("albert_heijn_packing_slip.txt").read)
  end

  test "a packing slip says which order it belongs to and when it arrives" do
    assert_equal "100000001", @slip.order_number
    assert_equal Date.new(2026, 8, 28), @slip.delivered_on
    assert_equal BigDecimal("119.93"), @slip.total_amount
  end

  test "a packing slip lists a line for every product that was packed" do
    assert_equal 37, @slip.lines.size
  end

  test "a line says what was packed, how much of it, and what it cost" do
    milk = @slip.lines.find { |line| line.name == "AH Lactosevrije houdbare volle melk" }

    assert_equal 16, milk.quantity
    assert_equal BigDecimal("23.84"), milk.full_amount
    assert_equal BigDecimal("23.84"), milk.paid_amount
  end

  test "a bonus is folded into the line of the product it discounted" do
    vivera = @slip.lines.find { |line| line.name == "Vivera Plantaardige kipstukjes" }

    assert_equal BigDecimal("13.96"), vivera.full_amount
    assert_equal BigDecimal("6.98"), vivera.discount_amount
    assert_equal BigDecimal("6.98"), vivera.paid_amount
  end

  test "a product nobody discounted was paid in full" do
    broccoli = @slip.lines.find { |line| line.name == "AH Broccoliroosjes" }

    assert_equal 0, broccoli.discount_amount
    assert_equal BigDecimal("1.49"), broccoli.paid_amount
  end

  test "the lines add up to the shelf total and the bonus the slip states" do
    assert_equal BigDecimal("137.39"), @slip.lines.sum(&:full_amount)
    assert_equal BigDecimal("27.81"), @slip.lines.sum(&:discount_amount)
  end

  test "what was added for free is not a purchase" do
    assert_empty @slip.lines.select { |line| line.name == "uitjes zegel" }
  end

  test "mail that is not a packing slip is refused" do
    assert_nil Importing::AlbertHeijn::PackingSlip.parse("Beste familie, hier is een nieuwsbrief.")
  end
end
