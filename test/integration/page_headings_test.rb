require "test_helper"

class PageHeadingsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:admin))
  end

  test "every page has exactly one h1 in its title bar" do
    pages.each do |path|
      get path

      assert_response :success, path
      assert_select "h1", { count: 1 }, "#{path} needs exactly one h1"
      assert_select "main > header > h1", { count: 1 }, "#{path} needs its h1 in the title bar"
    end
  end

  private

  def pages
    [
      dashboard_index_path, transactions_path, new_transaction_path, transaction_path(transactions(:debit_grocery)),
      edit_transaction_path(transactions(:debit_grocery)), new_transactions_import_path, accounts_path,
      account_path(accounts(:checking)), new_account_path, edit_account_path(accounts(:checking)),
      new_account_merge_path(accounts(:albert_heijn)),
      people_path, new_person_path, person_path(people(:etienne)), edit_person_path(people(:etienne)),
      groups_path, new_group_path, group_path(groups(:samen)), edit_group_path(groups(:samen)),
      categories_path, new_category_path, category_path(categories(:supermarket)),
      edit_category_path(categories(:supermarket)), chattels_path, new_chattel_path, chattel_path(chattels(:one)),
      edit_chattel_path(chattels(:one)), budgets_path, new_budget_path, budget_path(budgets(:active_budget)),
      edit_budget_path(budgets(:active_budget)), appropriations_path, new_appropriation_path,
      appropriation_path(appropriations(:christmas_serena)), edit_appropriation_path(appropriations(:christmas_serena)),
      products_path, product_path(products(:ah_ribbelchips)), edit_product_path(products(:ah_ribbelchips)),
      product_types_path, new_product_type_path, product_type_path(product_types(:naturel_chips)),
      edit_product_type_path(product_types(:naturel_chips)), receipts_path, todo_path, users_path,
      edit_user_profile_path(users(:admin)),
      user_profile_path(users(:member)), admin_root_path, admin_users_path, new_admin_user_path,
      admin_user_path(users(:member)), edit_admin_user_path(users(:member))
    ]
  end
end
