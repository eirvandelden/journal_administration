require "test_helper"

class UsersIndexTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "index lists the active users and leaves out inactive ones" do
    get users_path

    assert_response :success
    assert_select "a", text: users(:admin).name
    assert_select "a", text: users(:inactive).name, count: 0
  end
end
