require "test_helper"

class TodosControllerPageTest < ActiveSupport::TestCase
  test "the last page knows it is last" do
    assert_predicate TodosController::Page.new(3, 3), :last?
    assert_not TodosController::Page.new(2, 3).last?
  end

  test "a page before the last is before last" do
    assert_predicate TodosController::Page.new(2, 3), :before_last?
    assert_not TodosController::Page.new(3, 3).before_last?
  end

  test "the next page number is one more" do
    assert_equal 3, TodosController::Page.new(2, 5).next_param
  end
end
