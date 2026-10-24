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

  test "your own role box is disabled" do
    sign_in_as(users(:admin))

    get users_path

    assert_select "input##{dom_id(users(:admin), :role)}[disabled]"
    assert_select "input##{dom_id(users(:member), :role)}:not([disabled])"
  end

  test "a member sees every role box disabled" do
    get users_path

    assert_select "input[type=checkbox][id^=role_user_]", minimum: 2
    assert_select "input[type=checkbox][id^=role_user_]:not([disabled])", count: 0
  end
end
