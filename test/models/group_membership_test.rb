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

  test "refuses to add a household member to an outside group that owns an account with transactions" do
    group = Group.create!(name: "Outside group")
    group.group_memberships.create!(person: people(:grandma))
    account = Account.create!(name: "Outside group account", owner: nil, group:)
    Debit.create!(
      amount: 25, booked_at: Time.current, interest_at: Time.current,
      debitor: accounts(:savings), creditor: account, category: categories(:gifts)
    )

    membership = group.group_memberships.build(person: people(:etienne))

    assert_not membership.save
    assert_not_predicate group.reload, :household?
    assert_not GroupMembership.exists?(group_id: group.id, person_id: people(:etienne).id)
  end

  test "allows adding a household member to an outside group without account transactions" do
    group = Group.create!(name: "Unused outside group")
    group.group_memberships.create!(person: people(:grandma))
    Account.create!(name: "Unused outside group account", owner: nil, group:)

    assert group.group_memberships.create!(person: people(:etienne))
    assert_predicate group.reload, :household?
  end

  test "removing a membership keeps the person" do
    membership = group_memberships(:samen_etienne)

    assert membership.destroy
    assert Person.exists?(people(:etienne).id)
  end
end
