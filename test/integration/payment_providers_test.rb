require "test_helper"

class PaymentProvidersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
    @account = accounts(:adyen)
  end

  class Create < PaymentProvidersTest
    test "marks an external account as a shared provider" do
      post account_payment_provider_path(@account)

      assert_redirected_to account_path(@account)
      assert_predicate @account.reload, :payment_provider?
      assert_equal I18n.t("payment_providers.create.success"), flash[:notice]
    end

    test "refuses to mark a family account" do
      post account_payment_provider_path(accounts(:checking))

      assert_redirected_to account_path(accounts(:checking))
      assert_not accounts(:checking).reload.payment_provider?
      assert_match(/external/, flash[:alert])
    end
  end

  class Destroy < PaymentProvidersTest
    setup do
      @account.update!(payment_provider: true)
    end

    test "unmarks a provider" do
      delete account_payment_provider_path(@account)

      assert_redirected_to account_path(@account)
      assert_not @account.reload.payment_provider?
      assert_equal I18n.t("payment_providers.destroy.success"), flash[:notice]
    end

    test "unmarking a provider books new imports on it and leaves moved transactions" do
      post account_merchant_reassignment_path(@account)
      delete account_payment_provider_path(@account)

      Importing::ING::ImportJob.perform_now(
        [ "20260815", "Kruidvat", account_numbers(:checking).number, account_numbers(:adyen).number, "GT", "Af",
          "10,00", "Betaalautomaat", "Naam: Kruidvat IBAN: #{account_numbers(:adyen).number}", "1000,00", "" ]
      )

      assert_equal @account, Transaction.reorder(:id).last.debitor
      assert_equal accounts(:kruidvat), transactions(:kruidvat_through_adyen).reload.debitor
    end
  end

  class Unauthenticated < PaymentProvidersTest
    setup do
      delete session_path
    end

    test "redirects to login when signed out" do
      post account_payment_provider_path(@account)

      assert_redirected_to new_session_path
      assert_not @account.reload.payment_provider?
    end
  end
end
