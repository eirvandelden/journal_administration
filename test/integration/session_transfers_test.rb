require "test_helper"

class SessionTransfersTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
  end

  test "show renders the auto-submit login form" do
    get session_transfer_path(@member.transfer_id)

    assert_response :success
    assert_select "form"
  end

  test "update signs in an active user from a transfer link" do
    assert_difference("Session.count", 1) do
      put session_transfer_path(@member.transfer_id)
    end

    assert_redirected_to root_url
  end

  test "update rejects an invalid transfer link" do
    assert_no_difference("Session.count") do
      put session_transfer_path("invalid")
    end

    assert_response :bad_request
  end

  test "update rejects an inactive user transfer link" do
    assert_no_difference("Session.count") do
      put session_transfer_path(users(:inactive).transfer_id)
    end

    assert_response :bad_request
  end
end
