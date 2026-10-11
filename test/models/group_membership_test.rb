require "test_helper"

class GroupMembershipTest < ActiveSupport::TestCase
  test "refuses duplicate person" do
    duplicate = GroupMembership.new(group: groups(:samen), person: people(:etienne))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:person_id], "has already been taken"
  end

  test "refuses to remove the last household member from a used owner" do
    membership = group_memberships(:samen_etienne)
    group_memberships(:samen_michelle).destroy!

    assert_not membership.destroy
    assert GroupMembership.exists?(membership.id)
  end

  test "removing a membership keeps the person" do
    membership = group_memberships(:samen_etienne)

    assert membership.destroy
    assert Person.exists?(people(:etienne).id)
  end
end
