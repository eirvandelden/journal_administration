require "test_helper"

class ChattelTest < ActiveSupport::TestCase
  # -- name validation --------------------------------------------------------

  test "name must be present" do
    chattel = Chattel.new(name: nil)

    assert_not chattel.valid?
    assert_includes chattel.errors[:name], "can't be blank"
  end

  # -- purchase_price numericality --------------------------------------------

  test "purchase_price must be greater than 0" do
    chattel = Chattel.new(name: "Test", purchase_price: 0)

    assert_not chattel.valid?
    assert_includes chattel.errors[:purchase_price], "must be greater than 0"
  end

  test "purchase_price allows nil" do
    chattel = Chattel.new(name: "Test", purchase_price: nil)

    assert chattel.valid?
  end

  test "purchase_price accepts positive values" do
    chattel = Chattel.new(name: "Test", purchase_price: 99.99)

    assert chattel.valid?
  end

  # -- active scope -----------------------------------------------------------

  test "active scope includes chattels that have not left possession" do
    assert_includes Chattel.active, chattels(:one)
  end

  test "active scope excludes chattels that have left possession" do
    assert_not_includes Chattel.active, chattels(:two)
  end

  # -- left scope -------------------------------------------------------------

  test "left scope includes chattels that have left possession" do
    assert_includes Chattel.left, chattels(:two)
  end

  test "left scope excludes chattels still in possession" do
    assert_not_includes Chattel.left, chattels(:one)
  end

  # -- warrantied scope -------------------------------------------------------

  test "warrantied scope includes chattels with future warranty" do
    assert_includes Chattel.warrantied, chattels(:one)
  end

  test "warrantied scope excludes chattels with expired warranty" do
    assert_not_includes Chattel.warrantied, chattels(:two)
  end

  # -- out_of_warranty scope --------------------------------------------------

  test "out_of_warranty scope includes chattels with expired warranty" do
    assert_includes Chattel.out_of_warranty, chattels(:two)
  end

  test "out_of_warranty scope excludes chattels with future warranty" do
    assert_not_includes Chattel.out_of_warranty, chattels(:one)
  end

  # -- under_warranty? --------------------------------------------------------

  test "under_warranty? returns true when warranty is in the future" do
    assert chattels(:one).under_warranty?
  end

  test "under_warranty? returns false when warranty is in the past" do
    assert_not chattels(:two).under_warranty?
  end

  test "under_warranty? returns false when warranty_expires_at is nil" do
    assert_not Chattel.new(name: "No Warranty").under_warranty?
  end

  # -- active? ----------------------------------------------------------------

  test "active? returns true when left_possession_at is nil" do
    assert chattels(:one).active?
  end

  test "active? returns false when left_possession_at is set" do
    assert_not chattels(:two).active?
  end
end
