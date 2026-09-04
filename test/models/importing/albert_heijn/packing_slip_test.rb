require "test_helper"

class Importing::AlbertHeijn::PackingSlipTest < ActiveSupport::TestCase
  setup do
    @slip_text = file_fixture("albert_heijn_packing_slip.txt").read
    @slip = Importing::AlbertHeijn::PackingSlip.parse(@slip_text)
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

  test "a product sold by weight is priced by what it weighed" do
    slip = Importing::AlbertHeijn::PackingSlip.parse(
      file_fixture("albert_heijn_packing_slip_with_weighed_items.txt").read
    )
    cheese = slip.lines.find { |line| line.name == "AH Goudse Extra belegen 48+ pondstuk var" }

    assert_equal 1, cheese.quantity
    assert_equal BigDecimal("8.60"), cheese.full_amount
    assert_equal BigDecimal("4.30"), cheese.discount_amount
  end

  test "a slip of any size adds up to the totals it stated" do
    slip = Importing::AlbertHeijn::PackingSlip.parse(
      file_fixture("albert_heijn_packing_slip_with_weighed_items.txt").read
    )

    assert_equal 44, slip.lines.size
    assert_equal BigDecimal("170.26"), slip.lines.sum(&:full_amount)
    assert_equal BigDecimal("43.04"), slip.lines.sum(&:discount_amount)
  end

  test "a slip where nothing was on bonus records no discounts" do
    slip = Importing::AlbertHeijn::PackingSlip.parse(without_bonus_section(@slip_text))

    assert_equal 37, slip.lines.size
    assert_equal 0, slip.lines.sum(&:discount_amount)
    assert_equal BigDecimal("137.39"), slip.lines.sum(&:full_amount)
  end

  test "a mail missing the parts a slip is made of is refused" do
    without_products = @slip_text.sub("Aantal", "Iets anders")

    assert_nil Importing::AlbertHeijn::PackingSlip.parse(without_products)
  end

  test "two bonuses on the same product are added together" do
    doubled = @slip_text.sub(" AH Tonijnsalade \n\nBonus\n\n -0.75 \n\n",
                             " AH Tonijnsalade \n\nBonus\n\n -0.75 \n\n AH Tonijnsalade \n\nBonus\n\n -0.25 \n\n")
    slip = Importing::AlbertHeijn::PackingSlip.parse(doubled)
    tuna = slip.lines.find { |line| line.name == "AH Tonijnsalade" }

    assert_equal BigDecimal("1.00"), tuna.discount_amount
  end

  test "a slip whose product rows do not line up is refused" do
    mangled = @slip_text.sub(" AH Broccoliroosjes \n\n 1 \n\n 1.49 \n\n 1.49 \n\n",
" AH Broccoliroosjes \n\n 1 \n\n 1.49 \n\n")

    assert_nil Importing::AlbertHeijn::PackingSlip.parse(mangled)
  end

  private

  # The same mail with the bonus detail section taken out, as it arrives when
  # nothing was on bonus: the summary still names the bonus row, no detail follows.
  def without_bonus_section(mail)
    blocks = mail.split("\n\n")
    stripped = blocks.map(&:strip)
    first = stripped.rindex("Bonusvoordeel")
    last = stripped.index("Totaal voordeel")

    (blocks[0...first] + blocks[(last + 2)..]).join("\n\n")
  end
end
