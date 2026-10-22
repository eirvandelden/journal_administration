require "test_helper"

class Importing::AlbertHeijn::OrderConfirmationTest < ActiveSupport::TestCase
  setup do
    @confirmation = Importing::AlbertHeijn::OrderConfirmation.parse(
      file_fixture("albert_heijn_order_confirmation.txt").read
    )
  end

  test "reads the order number, planned delivery date and total" do
    assert_equal "100000003", @confirmation.order_number
    assert_equal Date.new(2023, 11, 3), @confirmation.delivered_on
    assert_equal 10_941, @confirmation.total_amount
  end

  test "reads one line per product, stepping over the shop heading" do
    reiniger = @confirmation.lines.find { |line| line.name == "AH Allesreiniger oceaan" }
    krentenbol = @confirmation.lines.find { |line| line.name == "AH Extra lang lekker rozijnen krentenbol" }

    assert_equal 43, @confirmation.lines.size
    assert_equal 129, reiniger.full_amount
    assert_equal [ 2, 438, 200 ], [ krentenbol.quantity, krentenbol.full_amount, krentenbol.discount_amount ]
    assert_equal 238, krentenbol.paid_amount
  end

  test "returns nothing for a packing slip" do
    assert_nil Importing::AlbertHeijn::OrderConfirmation.parse(file_fixture("albert_heijn_packing_slip.txt").read)
  end

  test "is not packed" do
    assert_not @confirmation.packed?
  end
end
