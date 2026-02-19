require "test_helper"

class SortableTest < ActiveSupport::TestCase
  test "sort_by_hierarchy sorts parent categories before their children" do
    parent = categories(:groceries)
    child = categories(:supermarket)
    records = { child => 100, parent => 200 }

    sorted = Category.sort_by_hierarchy(records)
    keys = sorted.keys

    assert_operator keys.index(parent), :<, keys.index(child)
  end

  test "sort_by_hierarchy sorts alphabetically within parents" do
    records = {
      categories(:housing) => 100,
      categories(:groceries) => 200
    }

    sorted = Category.sort_by_hierarchy(records)
    keys = sorted.keys

    assert_operator keys.index(categories(:groceries)), :<, keys.index(categories(:housing))
  end

  test "sort_by_hierarchy handles nil record" do
    records = { nil => 50, categories(:groceries) => 100 }

    sorted = Category.sort_by_hierarchy(records)

    assert_equal [nil, categories(:groceries)], sorted.keys
  end
end
