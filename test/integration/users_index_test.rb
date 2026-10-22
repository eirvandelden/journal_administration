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

  test "rows carry no remove button" do
    get users_path

    assert_select "button.button-danger", count: 0
    assert_select "main > header > h1", count: 1
  end
end
