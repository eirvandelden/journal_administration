require "test_helper"

class AccountMergesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @target = accounts(:albert_heijn)
    @duplicate = accounts(:albert_heijn_duplicate)
  end

  class Create < AccountMergesTest
    test "merging duplicates moves transactions, receipts and numbers and removes the duplicates" do
      moved_transactions = Transaction.by_account(@duplicate.id).pluck(:id)
      total_before = Transaction.by_account(@target.id).count + moved_transactions.size

      post account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }

      assert_redirected_to account_path(@target)
      assert_not Account.exists?(@duplicate.id)
      assert_equal total_before, Transaction.by_account(@target.id).count
      assert_empty moved_transactions - Transaction.by_account(@target.id).pluck(:id)
      assert_equal @target, receipts(:albert_heijn_duplicate_monday).reload.shop
      assert_equal %w[NL00ABNA9999999001 NL00ABNA9999999002 NL00ABNA9999999999], @target.reload.numbers.sort
      assert_equal "Albert Heijn B.V.", @target.name
    end

    test "a transaction from any of the three numbers shows under the merged account" do
      post account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }
      get account_path(@target)

      assert_includes response.body, transaction_path(transactions(:debit_from_ah_duplicate))
      assert_includes response.body, transaction_path(transactions(:credit_from_ah_duplicate))
      assert_includes response.body, "NL00ABNA9999999002"
    end

    test "the notice states how many transactions and receipts moved" do
      post account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }

      assert_match(/2 transactions/, flash[:notice])
      assert_match(/1 receipt/, flash[:notice])
    end

    test "merging a household account is refused" do
      assert_no_difference [ "Account.count", "AccountNumber.count" ] do
        post account_merge_path(@target), params: { duplicate_ids: [ accounts(:savings).id ] }
      end

      assert_redirected_to new_account_merge_path(@target, duplicate_ids: [ accounts(:savings).id ])
      assert_predicate flash[:alert], :present?
    end

    test "merging into a household account is refused" do
      assert_no_difference "Account.count" do
        post account_merge_path(accounts(:checking)), params: { duplicate_ids: [ @duplicate.id ] }
      end

      assert_predicate flash[:alert], :present?
      assert Account.exists?(@duplicate.id)
    end

    test "merging without picking duplicates is refused" do
      assert_no_difference "Account.count" do
        post account_merge_path(@target)
      end

      assert_predicate flash[:alert], :present?
    end
  end

  class New < AccountMergesTest
    test "without picks the page offers a search and suggests nothing" do
      get new_account_merge_path(@target)

      assert_response :success
      assert_select "form[method=get] input[name=query]"
      assert_select "input[type=checkbox][name='duplicate_ids[]']", count: 0
    end

    test "merge page lists external matches for the query and not the target" do
      get new_account_merge_path(@target), params: { query: "AH" }

      assert_response :success
      assert_select "input[type=checkbox][name='duplicate_ids[]'][value='#{@duplicate.id}']"
      assert_select "input[type=checkbox][name='duplicate_ids[]'][value='#{@target.id}']", count: 0
    end

    test "the search matches a duplicate by one of its numbers" do
      get new_account_merge_path(@target), params: { query: "NL00ABNA9999999002" }

      assert_select "input[type=checkbox][name='duplicate_ids[]'][value='#{@duplicate.id}']"
    end

    test "the search never lists household accounts" do
      get new_account_merge_path(@target), params: { query: "Spaarrekening" }

      assert_select "input[type=checkbox][name='duplicate_ids[]'][value='#{accounts(:savings).id}']", count: 0
    end

    test "the review step confirms with the transaction and receipt counts" do
      get new_account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }

      assert_response :success
      assert_select "[data-turbo-confirm*='2 transactions']"
      assert_select "[data-turbo-confirm*='1 receipt']"
      assert_select "[data-turbo-confirm*='#{@target.name}']"
    end

    test "the review step posts the picked ids to create" do
      get new_account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }

      assert_select "form[action='#{account_merge_path(@target)}'][method=post]" do
        assert_select "input[name='duplicate_ids[]'][value='#{@duplicate.id}']"
      end
    end

    test "without picks the page counts no transactions" do
      assert_empty queries_matching(/COUNT.*FROM "transactions"/) { get new_account_merge_path(@target) }
    end

    test "the review step changes nothing" do
      assert_no_difference [ "Account.count", "AccountNumber.count" ] do
        get new_account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }
      end
    end
  end

  class AccountPage < AccountMergesTest
    test "an external account page links to the merge page" do
      get account_path(@target)

      assert_select "a[href='#{new_account_merge_path(@target)}']"
    end

    test "a household account page has no merge link" do
      get account_path(accounts(:checking))

      assert_select "a[href='#{new_account_merge_path(accounts(:checking))}']", count: 0
    end
  end

  class Unauthenticated < AccountMergesTest
    setup do
      delete session_path
    end

    test "unauthenticated users are sent to sign in" do
      get new_account_merge_path(@target)

      assert_redirected_to new_session_path

      post account_merge_path(@target), params: { duplicate_ids: [ @duplicate.id ] }

      assert_redirected_to new_session_path
      assert Account.exists?(@duplicate.id)
    end
  end

  private

  # SQL statements that match the pattern while the block runs
  def queries_matching(pattern, &)
    statements = []
    counter = ->(*, payload) { statements << payload[:sql] if payload[:sql].match?(pattern) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    statements
  end
end
