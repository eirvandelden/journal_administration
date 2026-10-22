require "test_helper"

class Importing::AlbertHeijn::OlderPackingSlipTest < ActiveSupport::TestCase
  setup do
    @slip = Importing::AlbertHeijn::OlderPackingSlip.parse(file_fixture("albert_heijn_older_packing_slip.txt").read)
  end

  test "reads the order number, delivery date and total" do
    assert_equal "100000002", @slip.order_number
    assert_equal Date.new(2023, 9, 1), @slip.delivered_on
    assert_equal 12_109, @slip.total_amount
  end

  test "reads one line per product with its bonus folded in" do
    honey = @slip.lines.find { |line| line.name == "AH Biologisch Honing stroopwafels" }
    cucumbers = @slip.lines.find { |line| line.name == "AH Komkommer" }

    assert_equal 45, @slip.lines.size
    assert_equal [ 229, 23, 206 ], [ honey.full_amount, honey.discount_amount, honey.paid_amount ]
    assert_equal [ 2, 150, 0 ], [ cucumbers.quantity, cucumbers.full_amount, cucumbers.discount_amount ]
  end

  test "reads a weighed product by its total" do
    cheese = @slip.lines.find { |line| line.name == "AH Goudse jong belegen 48+ stuk" }

    assert_equal 811, cheese.full_amount
  end

  test "leaves out what Albert Heijn adds free of charge" do
    assert_not(@slip.lines.any? { |line| line.name.include?("Allerhande") })
  end

  test "returns nothing for a current packing slip" do
    assert_nil Importing::AlbertHeijn::OlderPackingSlip.parse(file_fixture("albert_heijn_packing_slip.txt").read)
  end

  test "is packed" do
    assert_predicate @slip, :packed?
  end
end
