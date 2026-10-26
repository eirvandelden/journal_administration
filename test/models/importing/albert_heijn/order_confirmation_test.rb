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

  test "reads the total when a note about deposit and stamps sits between its heading and the amount" do
    confirmation = Importing::AlbertHeijn::OrderConfirmation.parse(
      file_fixture("albert_heijn_order_confirmation_deposit_note.txt").read
    )

    assert_equal "100000004", confirmation.order_number
    assert_equal Date.new(2024, 8, 9), confirmation.delivered_on
    assert_equal 9_398, confirmation.total_amount
  end

  test "reads an order confirmation from before 2023, which words its headings differently" do
    older = parse_older

    assert_equal "100000005", older.order_number
    assert_equal Date.new(2023, 1, 20), older.delivered_on
    assert_equal 15_330, older.total_amount
    assert_not older.packed?
  end

  test "an older confirmation has one line per product, with the bonus that names a product folded in" do
    older = parse_older
    coffee = older.lines.find { |line| line.name == "Perla Huisblends Aroma koffiebonen" }

    assert_equal 66, older.lines.size
    assert_equal 17_702, older.lines.sum(&:full_amount)
    assert_equal [ 438 ], [ coffee.discount_amount ]
    assert_equal 1_461, older.lines.sum(&:discount_amount)
  end

  test "an older confirmation's deposit row is not a product" do
    assert_empty(parse_older.lines.select { |line| line.name.include?("Statiegeld") })
  end

  test "returns nothing for a packing slip" do
    assert_nil Importing::AlbertHeijn::OrderConfirmation.parse(file_fixture("albert_heijn_packing_slip.txt").read)
  end

  test "a confirmation whose products do not add up to its shelf total is refused" do
    mail = file_fixture("albert_heijn_order_confirmation.txt").read.sub(/(AH Aubergine\s+1\s+0\.92\s+)0\.92/, "\\10.93")

    assert_nil Importing::AlbertHeijn::OrderConfirmation.parse(mail)
  end

  test "a confirmation whose total does not follow from its shelf total and bonus is refused" do
    mail = file_fixture("albert_heijn_order_confirmation.txt").read.gsub("109.41", "109.42")

    assert_nil Importing::AlbertHeijn::OrderConfirmation.parse(mail)
  end

  test "is not packed" do
    assert_not @confirmation.packed?
  end

  private

  def parse_older
    Importing::AlbertHeijn::OrderConfirmation.parse(file_fixture("albert_heijn_older_order_confirmation.txt").read)
  end
end
