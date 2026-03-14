require "test_helper"

class AccountAliasesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:albert_heijn)
  end

  class Create < AccountAliasesTest
    test "creates an alias and redirects to account" do
      assert_difference "AccountAlias.count", 1 do
        post account_account_aliases_path(@account), params: { account_alias: { pattern: "Lidl " } }
      end

      assert_redirected_to account_path(@account)
      follow_redirect!
      assert_equal I18n.t("account_aliases.create.success"), flash[:notice]
    end

    test "redirects with error when pattern is blank" do
      assert_no_difference "AccountAlias.count" do
        post account_account_aliases_path(@account), params: { account_alias: { pattern: "" } }
      end

      assert_redirected_to account_path(@account)
    end

    test "does not create an alias for a family account" do
      family_account = accounts(:checking)

      assert_no_difference "AccountAlias.count" do
        post account_account_aliases_path(family_account), params: { account_alias: { pattern: "Shared" } }
      end

      assert_redirected_to account_path(family_account)
    end
  end

  class Destroy < AccountAliasesTest
    test "destroys an alias and redirects to account" do
      alias_record = account_aliases(:albert_heijn_ah)

      assert_difference "AccountAlias.count", -1 do
        delete account_account_alias_path(@account, alias_record)
      end

      assert_redirected_to account_path(@account)
      follow_redirect!
      assert_equal I18n.t("account_aliases.destroy.success"), flash[:notice]
    end
  end

  class Unauthenticated < AccountAliasesTest
    setup do
      delete session_path
    end

    test "create redirects to login" do
      post account_account_aliases_path(@account), params: { account_alias: { pattern: "Lidl " } }

      assert_redirected_to new_session_path
    end

    test "destroy redirects to login" do
      delete account_account_alias_path(@account, account_aliases(:albert_heijn_ah))

      assert_redirected_to new_session_path
    end
  end
end
