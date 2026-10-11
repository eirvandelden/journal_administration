require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "household? follows its household members" do
    assert_predicate groups(:samen), :household?
    group = Group.create!(name: "Outside")
    group.group_memberships.create!(person: people(:grandma))

    assert_not group.household?
  end

  test "cannot be destroyed when owned by an account" do
    assert_not groups(:samen).destroy
    assert Group.exists?(groups(:samen).id)
  end

  test "destroying an unused group keeps its people" do
    group = Group.create!(name: "Temporary")
    membership = group.group_memberships.create!(person: people(:grandpa))

    assert group.destroy
    assert Person.exists?(people(:grandpa).id)
    assert_not GroupMembership.exists?(membership.id)
  end
end
