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

  # -- recent_transactions ----------------------------------------------------

  test "recent_transactions returns transactions for the category" do
    result = categories(:supermarket).recent_transactions

    assert_includes result, transactions(:debit_grocery)
  end

  test "recent_transactions excludes transactions for other categories" do
    result = categories(:supermarket).recent_transactions

    assert_not_includes result, transactions(:credit_salary)
  end

  test "recent_transactions for a parent category includes child category transactions" do
    result = categories(:groceries).recent_transactions

    assert_includes result, transactions(:debit_grocery)
    assert_includes result, transactions(:debit_bakery)
  end

  test "recent_transactions respects the limit parameter" do
    result = categories(:supermarket).recent_transactions(limit: 0)

    assert_equal 0, result.count
  end

  test "recent_transactions defaults to a limit of ten" do
    11.times do |index|
      Transaction.create!(
        amount: 10 + index,
        booked_at: 40.days.from_now + index.minutes,
        interest_at: 40.days.from_now + index.minutes,
        debitor: accounts(:checking),
        creditor: accounts(:albert_heijn),
        category: categories(:supermarket)
      )
    end

    assert_equal 10, categories(:supermarket).recent_transactions.count
  end

  test "recent_transactions are ordered by booked_at descending" do
    older = Transaction.create!(
      amount: 40,
      booked_at: 50.days.from_now,
      interest_at: 50.days.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    newer = Transaction.create!(
      amount: 50,
      booked_at: 51.days.from_now,
      interest_at: 51.days.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )

    result_ids = categories(:supermarket).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ newer.id, older.id ], result_ids
  end

  test "recent_transactions break booked_at ties with newest record first" do
    timestamp = 70.days.from_now

    first = Transaction.create!(
      amount: 60,
      booked_at: timestamp,
      interest_at: timestamp,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    second = Transaction.create!(
      amount: 70,
      booked_at: timestamp,
      interest_at: timestamp,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )

    result_ids = categories(:supermarket).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ second.id, first.id ], result_ids
  end

  test "recent_transactions preloads associations used by the view" do
    relation = categories(:supermarket).recent_transactions

    assert_includes relation.includes_values, :creditor
    assert_includes relation.includes_values, :debitor
    assert_includes relation.includes_values, :category
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
