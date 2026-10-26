require "test_helper"

class Importing::AlbertHeijn::BonusesTest < ActiveSupport::TestCase
  test "reads what came off each product when the promotion comes before the amount" do
    bonuses = Importing::AlbertHeijn::Bonuses.new([ "AH Appel", "Bonus", "-0.30", "AH Peer", "2e GRATIS", "-1.05" ])

    assert_equal({ "AH Appel" => 30, "AH Peer" => 105 }, bonuses.by_product)
  end

  test "reads what came off each product when the amount comes before the promotion" do
    bonuses = Importing::AlbertHeijn::Bonuses.new([ "AH Appel", "0.30", "10% korting", "AH Peer", "1.05", "2e gratis" ])

    assert_equal({ "AH Appel" => 30, "AH Peer" => 105 }, bonuses.by_product)
  end

  test "adds up a second promotion that has no name of its own to the product above it" do
    entries = [ "AH Appel", "VOOR 0.89", "-0.16", "VOOR 0.89", "-0.16", "AH Peer", "Bonus", "-0.10" ]
    bonuses = Importing::AlbertHeijn::Bonuses.new(entries)

    assert_equal({ "AH Appel" => 32, "AH Peer" => 10 }, bonuses.by_product)
  end

  test "ignores a promotion that took nothing off" do
    bonuses = Importing::AlbertHeijn::Bonuses.new([ "AH Appel", "3 VOOR 5.00", "-0.00", "3 VOOR 5.00", "-0.32" ])

    assert_equal({ "AH Appel" => 32 }, bonuses.by_product)
  end

  test "reads nothing from an empty section" do
    assert_empty Importing::AlbertHeijn::Bonuses.new([]).by_product
  end
end
