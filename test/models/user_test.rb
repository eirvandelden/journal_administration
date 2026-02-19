require "test_helper"

class UserTest < ActiveSupport::TestCase
  # -- role enum --------------------------------------------------------------

  test "default role is member" do
    assert User.new.member?
  end

  test "can_administer? returns true for administrators" do
    assert users(:admin).can_administer?
  end

  test "can_administer? returns false for members" do
    assert_not users(:member).can_administer?
  end

  # -- locale enum ------------------------------------------------------------

  test "locale can be set to nl" do
    assert users(:admin).nl?
  end

  test "locale can be set to en" do
    assert users(:member).en?
  end

  # -- active scope -----------------------------------------------------------

  test "active scope returns only active users" do
    User.active.each do |user|
      assert user.active?
    end
  end

  test "active scope excludes inactive users" do
    assert_not_includes User.active, users(:inactive)
  end

  # -- ordered scope ----------------------------------------------------------

  test "ordered scope returns users ordered by name" do
    names = User.ordered.map(&:name)

    assert_equal names.sort, names
  end

  # -- deactivate -------------------------------------------------------------

  test "deactivate destroys all sessions for the user" do
    admin = users(:admin)
    assert admin.sessions.count > 0

    admin.deactivate

    assert_equal 0, admin.sessions.count
  end

  test "deactivate sets active to false" do
    admin = users(:admin)

    admin.deactivate

    assert_not admin.reload.active?
  end

  test "deactivate modifies the email address" do
    member = users(:member)
    original_email = member.email_address

    member.deactivate

    assert_not_equal original_email, member.reload.email_address
    assert_match(/-deactivated-/, member.email_address)
  end

  # -- current? ---------------------------------------------------------------

  test "current? returns true when user matches Current.user" do
    Current.user = users(:admin)

    assert users(:admin).current?
  end

  test "current? returns false when user does not match Current.user" do
    Current.user = users(:admin)

    assert_not users(:member).current?
  end
end
