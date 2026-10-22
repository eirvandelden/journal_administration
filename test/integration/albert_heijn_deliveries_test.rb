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

  private

  def packing_slip_for(order_number)
    @packing_slip.sub("100000001", order_number)
  end

  def bonus_on(receipt, product_name)
    receipt.lines.joins(:product).find_by!(products: { name: product_name }).discount_amount
  end
end
