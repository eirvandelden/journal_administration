require "test_helper"
require_relative "../test_helpers/assistant_requests"

class AlbertHeijnDeliveriesTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
    @packing_slip = file_fixture("albert_heijn_packing_slip.txt").read
    @older_pakbon = file_fixture("albert_heijn_older_packing_slip.txt").read
    @confirmation = file_fixture("albert_heijn_order_confirmation.txt").read
  end

  test "a packing slip becomes one delivery, and handing it over again changes nothing" do
    answer = ask_assistant("import_albert_heijn_mail", mail: @packing_slip)

    receipt = Receipt.find_by!(order_number: "100000001")

    assert_equal Date.new(2026, 8, 28), receipt.issued_on
    assert_equal 11_993, receipt.total_amount
    assert_equal 37, receipt.lines.count
    assert_includes answer, "order 100000001"
    assert_includes answer, "37 lines"
    assert_includes answer, "packed"

    assert_no_difference [ "Receipt.count", "ReceiptLine.count", "Product.count" ] do
      ask_assistant("import_albert_heijn_mail", mail: @packing_slip)
    end
  end

  test "an older pakbon becomes a delivery whose products and total match the mail" do
    ask_assistant("import_albert_heijn_mail", mail: @older_pakbon)

    receipt = Receipt.find_by!(order_number: "100000002")

    assert_equal Date.new(2023, 9, 1), receipt.issued_on
    assert_equal 12_109, receipt.total_amount
    assert_predicate receipt, :packed?
    assert_equal 45, receipt.lines.count
    assert_equal 12_129 - 2_475, receipt.basket_total
    assert_equal 23, bonus_on(receipt, "AH Biologisch Honing stroopwafels")
  end

  test "an order confirmation is recorded until its packing slip replaces the lines" do
    answer = ask_assistant("import_albert_heijn_mail", mail: @confirmation)

    receipt = Receipt.find_by!(order_number: "100000003")

    assert_equal Date.new(2023, 11, 3), receipt.issued_on
    assert_equal 10_941, receipt.total_amount
    assert_not receipt.packed?
    assert_equal 43, receipt.lines.count
    assert_includes answer, "ordered"

    ask_assistant("import_albert_heijn_mail", mail: packing_slip_for("100000003"))

    assert_predicate receipt.reload, :packed?
    assert_equal 37, receipt.lines.count
    assert_equal 1, Receipt.where(order_number: "100000003").count
  end

  test "a mail nobody can read is refused and saves nothing" do
    assert_no_difference [ "Receipt.count", "ReceiptLine.count", "Product.count" ] do
      assert refused?("import_albert_heijn_mail", mail: "Nieuwsbrief: deze week in de bonus")
    end
  end

  test "a delivery before the first month in scope is refused and saves nothing" do
    early = @older_pakbon.sub("1 september 2023", "4 oktober 2022")

    assert_no_difference [ "Receipt.count", "ReceiptLine.count", "Product.count" ] do
      assert refused?("import_albert_heijn_mail", mail: early)
    end
  end

  test "the assistant classifies a cucumber as groceries" do
    cucumber = Product.resolve_by_name("AH Komkommer")

    classify(cucumber, brand: "AH", type: "Komkommer", category: categories(:household_groceries))

    assert_equal "AH", cucumber.reload.brand
    assert_equal "Komkommer", cucumber.product_type.name
    assert_equal "Huishoudelijke uitgaven - Boodschappen", cucumber.product_type.category.full_name
  end

  test "the assistant books a cleaner to Huishoudelijk, not to Boodschappen" do
    cleaner = Product.resolve_by_name("AH Allesreiniger oceaan")

    classify(cleaner, brand: "AH", type: "Allesreiniger", category: categories(:household_cleaning))

    assert_equal "Huishoudelijke uitgaven - Huishoudelijk", cleaner.reload.product_type.category.full_name
  end

  test "naturel chips of two brands share one product type" do
    ours = Product.resolve_by_name("AH Naturel chips")
    theirs = Product.resolve_by_name("Lay's Naturel chips")

    classify(ours, brand: "AH", type: "Naturel chips", category: categories(:groceries))
    classify(theirs, brand: "Lay's", type: "naturel chips", category: categories(:groceries))

    assert_equal ours.reload.product_type, theirs.reload.product_type
    assert_equal 1, ProductType.where("LOWER(name) = ?", "naturel chips").count
  end

  test "a product the assistant leaves alone stays on the unclassified list" do
    unsure = Product.resolve_by_name("Mysterieuze doos 7")

    answer = ask_assistant("list_unclassified_products")

    assert_predicate unsure.reload, :unclassified?
    assert_includes answer, "#{unsure.id}: Mysterieuze doos 7 (no brand, no type)"
  end

  test "a brand and type set by hand survive the assistant" do
    by_hand = products(:ah_ribbelchips)
    other_type = ask_assistant("create_product_type", name: "Kaaschips", category_id: categories(:groceries).id)

    answer = ask_assistant("classify_product", product_id: by_hand.id, brand: "Albert Heijn",
      product_type_id: ProductType.find_by!(name: "Kaaschips").id)

    assert_includes other_type, "Kaaschips"
    assert_equal "AH", by_hand.reload.brand
    assert_equal product_types(:naturel_chips), by_hand.product_type
    assert_includes answer, "Kept the brand AH and the type Naturel chips"
  end

  test "a new category lands under Huishoudelijke uitgaven and its type books to it" do
    answer = ask_assistant("create_household_category", name: "Huisdieren")
    pets = Category.find_by!(name: "Huisdieren")
    dog_food = Product.resolve_by_name("Bonzo Purina Bonzo Adult")

    classify(dog_food, brand: "Purina", type: "Hondenvoer", category: pets)

    assert_includes answer, "Huishoudelijke uitgaven - Huisdieren"
    assert_equal categories(:household_expenses), pets.parent_category
    assert_equal "debit", pets.direction
    assert_equal pets, dog_food.reload.product_type.category
  end

  private

  def classify(product, brand:, type:, category:)
    ask_assistant("create_product_type", name: type, category_id: category.id)
    ask_assistant("classify_product", product_id: product.id, brand: brand,
      product_type_id: ProductType.where("LOWER(name) = ?", type.downcase).first.id)
  end

  def packing_slip_for(order_number)
    @packing_slip.sub("100000001", order_number)
  end

  def bonus_on(receipt, product_name)
    receipt.lines.joins(:product).find_by!(products: { name: product_name }).discount_amount
  end
end
