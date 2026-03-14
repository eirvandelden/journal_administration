require "test_helper"

class TransactionsUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @transfer = transactions(:transfer_savings)
    sign_in_as(@member)
  end

  test "edit explains that internal transfer categories are locked" do
    get edit_transaction_url(@transfer)

    assert_response :success
    assert_select "select[disabled][name='transaction[category_id]']"
    assert_select "p", text: I18n.t("transactions.form.transfer_category_locked")
  end

  test "update rejects changing an internal transfer to a non-transfer category" do
    patch transaction_url(@transfer), params: {
      transaction: {
        booked_at: @transfer.booked_at,
        interest_at: @transfer.interest_at,
        note: @transfer.note,
        category_id: categories(:supermarket).id
      }
    }

    assert_response :success
    assert_equal categories(:transfer), @transfer.reload.category
    assert_select "#error_explanation", text: /#{Regexp.escape(I18n.t("activerecord.errors.models.transaction.attributes.category.must_remain_transfer"))}/
  end
end
