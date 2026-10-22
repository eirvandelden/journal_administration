require "test_helper"
require Rails.root.join("db/migrate/20261022090000_reset_zero_parent_category_ids")

class ResetZeroParentCategoryIdsTest < ActiveSupport::TestCase
  test "up turns a parent of 0 into no parent" do
    category = categories(:groceries)
    category.update_column(:parent_category_id, 0)

    run_up

    assert_nil category.reload.parent_category_id
  end

  test "up keeps a real parent" do
    child = categories(:groceries)
    child.update_column(:parent_category_id, categories(:housing).id)

    run_up

    assert_equal categories(:housing).id, child.reload.parent_category_id
  end

  private

  def run_up
    migration = ResetZeroParentCategoryIds.new
    migration.suppress_messages { migration.up }
  end
end
