require "test_helper"

class MerchantReassignmentsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:adyen)
    @account.update!(payment_provider: true)
  end

  test "marking a provider leaves its transactions until they are moved" do
    @account.update!(payment_provider: false)
    post account_payment_provider_path(@account)

    assert_equal @account, transactions(:kruidvat_through_adyen).reload.debitor

    post account_merchant_reassignment_path(@account)

    assert_equal accounts(:kruidvat), transactions(:kruidvat_through_adyen).reload.debitor
  end

  test "a moved transaction with the provider's default category gets the merchant's default" do
    accounts(:kruidvat).update!(category: categories(:household))

    post account_merchant_reassignment_path(@account)

    assert_equal categories(:household), transactions(:kruidvat_through_adyen).reload.category
  end

  test "a moved transaction with the provider's default category loses it at a merchant without a default" do
    post account_merchant_reassignment_path(@account)

    assert_equal accounts(:kruidvat), transactions(:kruidvat_through_adyen).reload.debitor
    assert_nil transactions(:kruidvat_through_adyen).category
  end

  test "a moved transaction keeps a category chosen by hand" do
    accounts(:kruidvat).update!(category: categories(:household))

    post account_merchant_reassignment_path(@account)

    assert_equal categories(:bakery), transactions(:hand_categorised_through_adyen).reload.category
  end

  test "a moved split transaction keeps its splits" do
    accounts(:kruidvat).update!(category: categories(:household))
    payment = transactions(:kruidvat_through_adyen)
    payment.transaction_splits.create!(amount: 4, category: categories(:bakery))

    post account_merchant_reassignment_path(@account)

    assert_equal accounts(:kruidvat), payment.reload.debitor
    assert_equal categories(:gifts), payment.category
    assert_equal [ [ 4, categories(:bakery) ] ],
      payment.explicit_transaction_splits.map { |split| [ split.amount, split.category ] }
  end

  test "moving a second time moves nothing" do
    post account_merchant_reassignment_path(@account)

    assert_no_changes -> { Transaction.pluck(:id, :debitor_account_id, :creditor_account_id, :updated_at) } do
      post account_merchant_reassignment_path(@account)
    end
    assert_equal I18n.t("merchant_reassignments.create.success", count: 0), flash[:notice]
  end

  test "redirects with the number moved" do
    post account_merchant_reassignment_path(@account)

    assert_redirected_to account_path(@account)
    assert_equal I18n.t("merchant_reassignments.create.success", count: 3), flash[:notice]
  end

  test "redirects with an alert when a move fails" do
    failing = transactions(:kruidvat_through_adyen)
    failing.transaction_splits.create!(amount: 10, category: categories(:bakery))
    failing.update_column(:amount, 5)

    post account_merchant_reassignment_path(@account)

    assert_redirected_to account_path(@account)
    assert_match(/Amount/, flash[:alert])
    assert_match(/##{failing.id}\b/, flash[:alert])
    assert_equal @account, failing.reload.debitor
  end

  test "redirects to login when signed out" do
    delete session_path

    post account_merchant_reassignment_path(@account)

    assert_redirected_to new_session_path
  end
end
