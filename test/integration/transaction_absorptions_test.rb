require "test_helper"

class TransactionAbsorptionsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:albert_heijn)
  end

  class Create < TransactionAbsorptionsTest
    test "reassigns creditor transactions from duplicate account to canonical account" do
      duplicate = accounts(:albert_heijn_duplicate)
      transaction = transactions(:debit_from_ah_duplicate)

      assert_equal duplicate, transaction.creditor

      post account_transaction_absorption_path(@account)

      transaction.reload
      assert_equal @account, transaction.creditor
    end

    test "reassigns debitor transactions from duplicate account to canonical account" do
      duplicate = accounts(:albert_heijn_duplicate)
      transaction = transactions(:credit_from_ah_duplicate)

      assert_equal duplicate, transaction.debitor

      post account_transaction_absorption_path(@account)

      transaction.reload
      assert_equal @account, transaction.debitor
    end

    test "redirects to account with success notice" do
      post account_transaction_absorption_path(@account)

      assert_redirected_to account_path(@account)
      follow_redirect!
      assert_equal I18n.t("transaction_absorptions.create.success"), flash[:notice]
    end
  end

  class Unauthenticated < TransactionAbsorptionsTest
    setup do
      delete session_path
    end

    test "redirects to login" do
      post account_transaction_absorption_path(@account)

      assert_redirected_to new_session_path
    end
  end
end
