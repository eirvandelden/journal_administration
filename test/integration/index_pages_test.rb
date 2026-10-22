require "test_helper"

class IndexPagesTest < ActionDispatch::IntegrationTest
  INDEXES_WITH_NEW = {
    transactions_path: :new_transaction_path,
    accounts_path: :new_account_path,
    people_path: :new_person_path,
    groups_path: :new_group_path,
    categories_path: :new_category_path,
    chattels_path: :new_chattel_path,
    budgets_path: :new_budget_path,
    appropriations_path: :new_appropriation_path,
    product_types_path: :new_product_type_path,
    admin_users_path: :new_admin_user_path
  }.freeze

  ALL_INDEXES = %i[
    transactions_path accounts_path people_path groups_path categories_path chattels_path budgets_path
    appropriations_path receipts_path products_path product_types_path todo_path admin_users_path
  ].freeze

  setup do
    sign_in_as(users(:admin))
  end

  test "every index with a new route has + Nieuw in its title bar" do
    INDEXES_WITH_NEW.each do |index, new_route|
      get public_send(index)

      assert_select "main > header nav a[href=?]", public_send(new_route), { text: /\+/ }, "#{index} needs + Nieuw"
    end
  end

  test "no index shows a database ID column" do
    ALL_INDEXES.each do |name|
      get public_send(name)

      assert_select "th", { text: /\A\s*(Id|ID)\s*\z/, count: 0 }, "#{name} shows an ID column"
    end
  end

  test "every index table stacks with a data-label on every cell" do
    ALL_INDEXES.each do |name|
      get public_send(name)

      assert_select "main table:not([data-stack])", { count: 0 }, "#{name} has a table that does not stack"
      assert_select "main table[data-stack] tbody td:not([data-label])", { count: 0 }, "#{name} has unlabelled cells"
    end
  end
end
