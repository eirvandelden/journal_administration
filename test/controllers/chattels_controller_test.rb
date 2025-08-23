require "test_helper"

class ChattelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chattel = chattels(:one)
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
      post chattels_url, params: { chattel: { kind: @chattel.kind, left_possession_at: @chattel.left_possession_at, model_number: @chattel.model_number, name: @chattel.name, notes: @chattel.notes, purchase_price: @chattel.purchase_price, purchase_transaction_id: @chattel.purchase_transaction_id, purchased_at: @chattel.purchased_at, serial_number: @chattel.serial_number, warranty_expires_at: @chattel.warranty_expires_at } }
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
    patch chattel_url(@chattel), params: { chattel: { kind: @chattel.kind, left_possession_at: @chattel.left_possession_at, model_number: @chattel.model_number, name: @chattel.name, notes: @chattel.notes, purchase_price: @chattel.purchase_price, purchase_transaction_id: @chattel.purchase_transaction_id, purchased_at: @chattel.purchased_at, serial_number: @chattel.serial_number, warranty_expires_at: @chattel.warranty_expires_at } }
    assert_redirected_to chattel_url(@chattel)
  end

  test "should destroy chattel" do
    assert_difference("Chattel.count", -1) do
      delete chattel_url(@chattel)
    end

    assert_redirected_to chattels_url
  end
end
