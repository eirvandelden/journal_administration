require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  # -- direction enum ---------------------------------------------------------

  test "debit? returns true for debit categories" do
    assert categories(:groceries).debit?
  end

  test "credit? returns true for credit categories" do
    assert categories(:income).credit?
  end

  # -- direction validation ---------------------------------------------------

  test "direction must be present" do
    category = Category.new(name: "Invalid")

    assert_not category.valid?
    assert_includes category.errors[:direction], "can't be blank"
  end

  # -- parent-child hierarchy -------------------------------------------------

  test "secondaries returns child categories" do
    assert_includes categories(:groceries).secondaries, categories(:supermarket)
  end

  test "parent_category returns the parent" do
    assert_equal categories(:groceries), categories(:supermarket).parent_category
  end

  test "parent_category is nil for top-level categories" do
    assert_nil categories(:groceries).parent_category
  end

  # -- children method --------------------------------------------------------

  test "children includes the category itself and its direct children" do
    children = categories(:groceries).children

    assert_includes children, categories(:groceries)
    assert_includes children, categories(:supermarket)
  end

  test "children for a leaf category includes only itself" do
    children = categories(:supermarket).children

    assert_includes children, categories(:supermarket)
    assert_equal 1, children.count
  end

  # -- full_name --------------------------------------------------------------

  test "full_name returns Parent - Child for child categories" do
    assert_equal "Groceries - Supermarket", categories(:supermarket).full_name
  end

  test "full_name returns just the name for parent categories" do
    assert_equal "Groceries", categories(:groceries).full_name
  end

  # -- to_s -------------------------------------------------------------------

  test "to_s returns the name" do
    assert_equal "Groceries", categories(:groceries).to_s
  end

  # -- groups scope -----------------------------------------------------------

  test "groups scope returns only parent categories" do
    groups = Category.groups

    groups.each do |category|
      assert_nil category.parent_category_id
    end
  end

  test "groups scope excludes child categories" do
    groups = Category.groups

    assert_not_includes groups, categories(:supermarket)
    assert_not_includes groups, categories(:rent)
    assert_not_includes groups, categories(:salary)
  end

  # -- default scope ----------------------------------------------------------

  test "default scope orders categories by name ascending" do
    names = Category.all.map(&:name)

    assert_equal names.sort, names
  end
end
