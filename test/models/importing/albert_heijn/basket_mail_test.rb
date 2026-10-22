require "test_helper"

class Importing::AlbertHeijn::BasketMailTest < ActiveSupport::TestCase
  test "reads a packing slip" do
    basket = parse("albert_heijn_packing_slip.txt")

    assert_instance_of Importing::AlbertHeijn::PackingSlip, basket
  end

  test "reads an older pakbon" do
    assert_instance_of Importing::AlbertHeijn::OlderPackingSlip, parse("albert_heijn_older_packing_slip.txt")
  end

  test "reads an order confirmation" do
    assert_instance_of Importing::AlbertHeijn::OrderConfirmation, parse("albert_heijn_order_confirmation.txt")
  end

  test "returns nothing for a newsletter" do
    assert_nil Importing::AlbertHeijn::BasketMail.parse("Nieuwsbrief: deze week in de bonus")
  end

  test "returns nothing when a reader trips over a malformed amount" do
    mail = file_fixture("albert_heijn_older_packing_slip.txt").read.sub("121.09", "honderd")

    assert_nil Importing::AlbertHeijn::BasketMail.parse(mail)
  end

  test "returns nothing when a reader trips over an unknown month" do
    mail = file_fixture("albert_heijn_older_packing_slip.txt").read.sub("september", "septembre")

    assert_nil Importing::AlbertHeijn::BasketMail.parse(mail)
  end

  private

  def parse(fixture) = Importing::AlbertHeijn::BasketMail.parse(file_fixture(fixture).read)
end
