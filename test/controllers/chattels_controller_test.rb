require "test_helper"

class ChattelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chattel = chattels(:one)
    sign_in_as users(:admin)
  end

  test "should get index" do
    get chattels_url
    assert_response :success
  end

  test "should get new" do
    get new_chattel_url
    assert_response :success
  end

  test "should create chattel" do
    assert_difference("Chattel.count") do
      post chattels_url,
           params: { chattel: chattel_params }
    end

    assert_redirected_to chattel_url(Chattel.last)
  end

  test "should show chattel" do
    get chattel_url(@chattel)
    assert_response :success
  end

  test "should get edit" do
    get edit_chattel_url(@chattel)
    assert_response :success
  end

  test "should update chattel" do
    patch chattel_url(@chattel),
          params: { chattel: chattel_params }
    assert_redirected_to chattel_url(@chattel)
  end

  test "should destroy chattel" do
    assert_difference("Chattel.count", -1) do
      delete chattel_url(@chattel)
    end

    assert_redirected_to chattels_url
  end

  private

  def sign_in_as(user)
    post session_url, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end

  def chattel_params
    @chattel.attributes.symbolize_keys.slice(
      :kind, :left_possession_at, :model_number, :name, :notes,
      :purchase_price, :purchase_transaction_id, :purchased_at,
      :serial_number, :warranty_expires_at
    )
  end
end
