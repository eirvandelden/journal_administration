require "test_helper"

class Assistant::CreateHouseholdCategoryTest < ActiveSupport::TestCase
  test "creates the category under Huishoudelijke uitgaven" do
    response = Assistant::CreateHouseholdCategory.call(name: "Huisdieren", server_context: nil)

    assert_not response.error?
    assert_includes response.content.first[:text], "Huishoudelijke uitgaven - Huisdieren"
  end

  test "answers the existing category when called again" do
    assert_no_difference "Category.count" do
      Assistant::CreateHouseholdCategory.call(name: "Boodschappen", server_context: nil)
    end
  end

  test "refuses a blank name" do
    assert_predicate Assistant::CreateHouseholdCategory.call(name: " ", server_context: nil), :error?
  end

  test "refuses when the group is missing" do
    categories(:household_expenses).secondaries.update_all(parent_category_id: nil)
    categories(:household_expenses).destroy!

    assert_predicate Assistant::CreateHouseholdCategory.call(name: "Huisdieren", server_context: nil), :error?
  end
end
