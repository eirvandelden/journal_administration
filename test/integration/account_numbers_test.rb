require "test_helper"

class AccountNumbersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:albert_heijn_duplicate)
  end

  class Showing < AccountNumbersTest
    test "the account page lists every number" do
      get account_path(@account)

      assert_response :success
      assert_includes response.body, "NL00ABNA9999999001"
      assert_includes response.body, "NL00ABNA9999999002"
    end

    test "the edit page shows each number and one empty field" do
      get edit_account_path(@account)

      assert_response :success
      assert_select "input[name$='[number]']", count: 3
      assert_select "input[name$='[number]'][value='NL00ABNA9999999001']"
      assert_select "input[name$='[number]'][value='']", count: 1
      assert_select "input[type=checkbox][name$='[_destroy]']", count: 2
    end

    test "the new page shows one empty number field" do
      get new_account_path

      assert_response :success
      assert_select "input[name$='[number]']", count: 1
    end
  end

  class Saving < AccountNumbersTest
    test "adds a number to an account" do
      assert_difference "AccountNumber.count", 1 do
        patch account_path(@account), params: {
          account: { account_numbers_attributes: { "0" => { number: "NL00ABNA9999999003" } } }
        }
      end

      assert_redirected_to account_path(@account)
      assert_includes @account.reload.numbers, "NL00ABNA9999999003"
    end

    test "removes a number from an account" do
      removed = account_numbers(:albert_heijn_duplicate_first)

      assert_difference "AccountNumber.count", -1 do
        patch account_path(@account), params: {
          account: { account_numbers_attributes: { "0" => { id: removed.id, _destroy: "1" } } }
        }
      end

      assert_equal %w[NL00ABNA9999999002], @account.reload.numbers
    end

    test "creates an account with a number" do
      assert_difference [ "Account.count", "AccountNumber.count" ], 1 do
        post accounts_path, params: {
          account: { name: "Lidl", account_numbers_attributes: { "0" => { number: "NL00LIDL0000000001" } } }
        }
      end

      assert_equal %w[NL00LIDL0000000001], Account.find_by!(name: "Lidl").numbers
    end

    test "an empty number field adds nothing" do
      assert_no_difference "AccountNumber.count" do
        patch account_path(@account), params: { account: { account_numbers_attributes: { "0" => { number: "" } } } }
      end

      assert_redirected_to account_path(@account)
    end

    test "saving a number of another account is refused and names that account" do
      assert_no_difference "AccountNumber.count" do
        patch account_path(accounts(:jumbo)), params: {
          account: { account_numbers_attributes: { "0" => { number: account_numbers(:albert_heijn).number } } }
        }
      end

      assert_includes response.body, account_numbers(:albert_heijn).number
      assert_includes response.body, accounts(:albert_heijn).name
    end

    test "saving a number of another account typed with spaces and lower case is refused" do
      assert_no_difference "AccountNumber.count" do
        patch account_path(accounts(:jumbo)), params: {
          account: { account_numbers_attributes: { "0" => { number: "nl00 abna 9999 999999" } } }
        }
      end

      assert_includes response.body, accounts(:albert_heijn).name
    end

    test "saving the same number twice is refused" do
      assert_no_difference "AccountNumber.count" do
        patch account_path(accounts(:jumbo)), params: {
          account: {
            account_numbers_attributes: {
              "0" => { number: "NL00JUMB0000000009" }, "1" => { number: "NL00JUMB0000000009" }
            }
          }
        }
      end

      assert_select "#error_explanation"
    end
  end

  class Unauthenticated < AccountNumbersTest
    setup do
      delete session_path
    end

    test "adding a number redirects to login" do
      assert_no_difference "AccountNumber.count" do
        patch account_path(@account), params: {
          account: { account_numbers_attributes: { "0" => { number: "NL00X" } } }
        }
      end

      assert_redirected_to new_session_path
    end
  end
end
