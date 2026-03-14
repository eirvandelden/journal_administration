require "test_helper"

class TransactionSplitsTest < ActionDispatch::IntegrationTest
  class Create < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
      @debit = transactions(:uncategorized)
    end

    test "adds a split and remainder to the transaction" do
      assert_difference "TransactionSplit.count", 2 do
        post transaction_transaction_splits_url(@debit),
          params: { transaction_split: { category_id: categories(:supermarket).id, amount: 10.00, note: "Test" } }
      end

      assert_response :redirect
      assert_redirected_to edit_transaction_url(@debit)

      remainder = @debit.transaction_splits.find_by(remainder: true)
      assert remainder
      assert_equal 15.00, remainder.amount
    end

    test "via turbo stream re-renders splits frame" do
      post transaction_transaction_splits_url(@debit),
        params: { transaction_split: { category_id: categories(:supermarket).id, amount: 10.00, note: "Test" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success
      assert_match "transaction_splits", response.body
    end

    test "with invalid amount returns 422" do
      post transaction_transaction_splits_url(@debit),
        params: { transaction_split: { amount: 999.99 } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :unprocessable_entity
      assert_includes response.body, I18n.t("activerecord.errors.models.transaction_split.attributes.amount.exceeds_transaction")
    end

    test "rejects transfer transactions" do
      transfer = transactions(:transfer_savings)

      assert_no_difference "TransactionSplit.count" do
        post transaction_transaction_splits_url(transfer),
          params: { transaction_split: { amount: 10.00 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      assert_response :unprocessable_entity
      assert_includes response.body, I18n.t("activerecord.errors.models.transaction_split.attributes.financial_transaction.must_not_be_transfer")
    end
  end

  class Update < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
      @split = transaction_splits(:split_grocery_supermarket)
      @transaction = transactions(:debit_grocery)
    end

    test "changes the split" do
      patch transaction_transaction_split_url(@transaction, @split),
        params: { transaction_split: { amount: 20.00 } }

      assert_response :redirect
      assert_redirected_to edit_transaction_url(@transaction)
      assert_equal 20.00, @split.reload.amount.to_f
    end

    test "via turbo stream re-renders splits frame" do
      patch transaction_transaction_split_url(@transaction, @split),
        params: { transaction_split: { amount: 20.00 } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success
    end

    test "with invalid amount returns 422" do
      patch transaction_transaction_split_url(@transaction, @split),
        params: { transaction_split: { amount: 999.99 } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :unprocessable_entity
      assert_includes response.body, I18n.t("activerecord.errors.models.transaction_split.attributes.amount.exceeds_transaction")
    end
  end

  class Destroy < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
      @split = transaction_splits(:split_grocery_supermarket)
      @transaction = transactions(:debit_grocery)
    end

    test "removes the split and adjusts remainder" do
      delete transaction_transaction_split_url(@transaction, @split)

      assert_response :redirect
      assert_redirected_to edit_transaction_url(@transaction)
      assert_not @transaction.transaction_splits.exists?(id: @split.id)

      remainder = @transaction.transaction_splits.find_by(remainder: true)
      assert remainder
      assert_equal 40.00, remainder.amount
    end

    test "via turbo stream re-renders splits frame" do
      delete transaction_transaction_split_url(@transaction, @split),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success
    end
  end

  class RemainderManagement < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
      @debit = transactions(:uncategorized)
    end

    test "creating a split auto-creates a remainder split" do
      post transaction_transaction_splits_url(@debit),
        params: { transaction_split: { category_id: categories(:supermarket).id, amount: 10.00 } }

      remainder = @debit.transaction_splits.find_by(remainder: true)
      assert remainder
      assert_equal 15.00, remainder.amount
    end

    test "updating a split adjusts the remainder" do
      post transaction_transaction_splits_url(@debit),
        params: { transaction_split: { category_id: categories(:supermarket).id, amount: 10.00 } }

      explicit_split = @debit.transaction_splits.find_by(remainder: false)
      patch transaction_transaction_split_url(@debit, explicit_split),
        params: { transaction_split: { amount: 20.00 } }

      remainder = @debit.transaction_splits.reload.find_by(remainder: true)
      assert remainder
      assert_equal 5.00, remainder.amount
    end

    test "deleting last explicit split removes remainder too" do
      post transaction_transaction_splits_url(@debit),
        params: { transaction_split: { category_id: categories(:supermarket).id, amount: 10.00 } }

      explicit_split = @debit.transaction_splits.find_by(remainder: false)
      delete transaction_transaction_split_url(@debit, explicit_split)

      assert_not @debit.reload.split?
    end

    test "creating a split that covers full amount creates no remainder" do
      assert_difference "TransactionSplit.count", 1 do
        post transaction_transaction_splits_url(@debit),
          params: { transaction_split: { category_id: categories(:supermarket).id, amount: 25.00 } }
      end

      assert_nil @debit.transaction_splits.find_by(remainder: true)
    end
  end

  class EditPageRendering < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
    end

    test "shows splits frame for Debit transactions" do
      get edit_transaction_url(transactions(:uncategorized))

      assert_response :success
      assert_select "turbo-frame#transaction_splits"
    end

    test "hides splits frame for Transfer transactions" do
      get edit_transaction_url(transactions(:transfer_savings))

      assert_response :success
      assert_select "turbo-frame#transaction_splits", count: 0
    end
  end
end
