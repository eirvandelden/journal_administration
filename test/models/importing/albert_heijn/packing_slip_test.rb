require "test_helper"

class Importing::AlbertHeijn::PackingSlipTest < ActiveSupport::TestCase
  setup do
    @slip_text = file_fixture("albert_heijn_packing_slip.txt").read
    @slip = Importing::AlbertHeijn::PackingSlip.parse(@slip_text)
  end

  test "a packing slip says which order it belongs to and when it arrives" do
    assert_equal "100000001", @slip.order_number
    assert_equal Date.new(2026, 8, 28), @slip.delivered_on
    assert_equal 11993, @slip.total_amount
  end

  test "reads lines and total as cents" do
    assert_instance_of Integer, @slip.total_amount
    assert(@slip.lines.all? { |line| line.full_amount.is_a?(Integer) && line.paid_amount.is_a?(Integer) })
  end

  test "a packing slip lists a line for every product that was packed" do
    assert_equal 37, @slip.lines.size
  end

  test "a line says what was packed, how much of it, and what it cost" do
    milk = @slip.lines.find { |line| line.name == "AH Lactosevrije houdbare volle melk" }

    assert_equal 16, milk.quantity
    assert_equal 2384, milk.full_amount
    assert_equal 2384, milk.paid_amount
  end

  test "a bonus is folded into the line of the product it discounted" do
    vivera = @slip.lines.find { |line| line.name == "Vivera Plantaardige kipstukjes" }

    assert_equal 1396, vivera.full_amount
    assert_equal 698, vivera.discount_amount
    assert_equal 698, vivera.paid_amount
  end

  test "a product nobody discounted was paid in full" do
    broccoli = @slip.lines.find { |line| line.name == "AH Broccoliroosjes" }

    assert_equal 0, broccoli.discount_amount
    assert_equal 149, broccoli.paid_amount
  end

  test "the lines add up to the shelf total and the bonus the slip states" do
    assert_equal 13739, @slip.lines.sum(&:full_amount)
    assert_equal 2781, @slip.lines.sum(&:discount_amount)
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
    assert_equal 860, cheese.full_amount
    assert_equal 430, cheese.discount_amount
  end

  test "a slip of any size adds up to the totals it stated" do
    slip = Importing::AlbertHeijn::PackingSlip.parse(
      file_fixture("albert_heijn_packing_slip_with_weighed_items.txt").read
    )

    assert_equal 44, slip.lines.size
    assert_equal 17026, slip.lines.sum(&:full_amount)
    assert_equal 4304, slip.lines.sum(&:discount_amount)
  end

  test "a slip where nothing was on bonus records no discounts" do
    slip = Importing::AlbertHeijn::PackingSlip.parse(without_bonus_section(@slip_text))

    assert_equal 37, slip.lines.size
    assert_equal 0, slip.lines.sum(&:discount_amount)
    assert_equal 13739, slip.lines.sum(&:full_amount)
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

    assert_equal 100, tuna.discount_amount
  end

  test "a second bonus under no product name belongs to the product above it" do
    tuna_bonus = " AH Tonijnsalade \n\nBonus\n\n -0.75 \n\n"
    continued = @slip_text.sub(tuna_bonus, "#{tuna_bonus} 2 VOOR 3.50 \n\n -0.25 \n\n")
    slip = Importing::AlbertHeijn::PackingSlip.parse(continued)

    assert_equal 100, slip.lines.find { |line| line.name == "AH Tonijnsalade" }.discount_amount
    assert_equal 2781 + 25, slip.lines.sum(&:discount_amount)
  end

  test "an empty bonus is ignored" do
    tuna_bonus = " AH Tonijnsalade \n\nBonus\n\n -0.75 \n\n"
    empty = "#{tuna_bonus} 2 VOOR 3.50 \n\n -0.00 \n\n"
    slip = Importing::AlbertHeijn::PackingSlip.parse(@slip_text.sub(tuna_bonus, empty))

    assert_equal 75, slip.lines.find { |line| line.name == "AH Tonijnsalade" }.discount_amount
  end

  test "a slip whose product rows do not line up is refused" do
    mangled = @slip_text.sub(" AH Broccoliroosjes \n\n 1 \n\n 1.49 \n\n 1.49 \n\n",
" AH Broccoliroosjes \n\n 1 \n\n 1.49 \n\n")

    assert_nil Importing::AlbertHeijn::PackingSlip.parse(mangled)
  end

  test "a slip whose total does not follow from its shelf total and bonus is refused" do
    assert_nil Importing::AlbertHeijn::PackingSlip.parse(@slip_text.gsub("119.93", "119.94"))
  end

  test "is packed" do
    assert_predicate Importing::AlbertHeijn::PackingSlip.parse(@slip_text), :packed?
  end

  test "returns nothing for an order confirmation" do
    confirmation = file_fixture("albert_heijn_order_confirmation.txt").read

    assert_nil Importing::AlbertHeijn::PackingSlip.parse(confirmation)
  end

  private

  # The same mail with the bonus detail section taken out, as it arrives when
  # nothing was on bonus: the summary still names the bonus row, no detail follows,
  # and the total is the shelf total plus the deposit.
  def without_bonus_section(mail)
    blocks = mail.split("\n\n")
    stripped = blocks.map(&:strip)
    first = stripped.rindex("Bonusvoordeel")
    last = stripped.index("Totaal voordeel")

    (blocks[0...first] + blocks[(last + 2)..]).join("\n\n").gsub("119.93", "147.74").sub("-27.81", "0.00")
  end
end
