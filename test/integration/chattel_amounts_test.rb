require "test_helper"

class ChattelAmountsTest < ActionDispatch::IntegrationTest
  setup do
    @chattel = chattels(:one)
    sign_in_as(users(:admin))
  end

  test "a numeric JSON purchase price in euros stores cents" do
    patch chattel_url(@chattel), params: { chattel: { purchase_price: 12.5 } },
      as: :json, headers: { "Accept" => "text/html" }

    assert_response :redirect
    assert_equal 1250, @chattel.reload.purchase_price
  end

  test "a JSON purchase price with a fraction of a cent answers 422" do
    patch chattel_url(@chattel, format: :json),
      params: { chattel: { purchase_price: 12.345 } }, as: :json

    assert_response :unprocessable_entity
  end
end
