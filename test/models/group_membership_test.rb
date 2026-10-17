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
      amount: 2500, booked_at: Time.current, interest_at: Time.current,
      debitor: accounts(:savings), creditor: account, category: categories(:gifts)
    )

    membership = group.group_memberships.build(person: people(:etienne))

    assert_not membership.save
    assert_not_predicate group.reload, :household?
    assert_not GroupMembership.exists?(group_id: group.id, person_id: people(:etienne).id)
  end

  test "refuses to replace the last household member of a used owner" do
    group = Group.create!(name: "Used household group")
    membership = group.group_memberships.create!(person: people(:etienne))
    account = Account.create!(name: "Used household account", owner: nil, group:)
    transaction = Debit.create!(
      amount: 2500, booked_at: Time.current, interest_at: Time.current,
      debitor: account, creditor: accounts(:albert_heijn), category: categories(:groceries)
    )

    assert_not membership.update(person: people(:grandma))
    assert_predicate membership.errors, :any?
    assert_equal group.id, membership.reload.group_id
    assert_equal people(:etienne).id, membership.person_id
    assert_predicate group.reload, :household?
    assert_equal "Debit", transaction.reload.type
    assert_equal 2500, transaction.amount
  end

  test "refuses to move the last household member out of a used owner" do
    group = Group.create!(name: "Used household group")
    membership = group.group_memberships.create!(person: people(:etienne))
    account = Account.create!(name: "Used household account", owner: nil, group:)
    transaction = Debit.create!(
      amount: 2500, booked_at: Time.current, interest_at: Time.current,
      debitor: account, creditor: accounts(:albert_heijn), category: categories(:groceries)
    )
    destination = Group.create!(name: "Another group")
    destination.group_memberships.create!(person: people(:grandma))

    assert_not membership.update(group: destination)
    assert_predicate membership.errors, :any?
    assert_equal group.id, membership.reload.group_id
    assert_equal people(:etienne).id, membership.person_id
    assert_predicate group.reload, :household?
    assert_equal "Debit", transaction.reload.type
    assert_equal 2500, transaction.amount
  end

  test "allows replacing the last household member with another household member when the owner has transactions" do
    group = Group.create!(name: "Used household group")
    membership = group.group_memberships.create!(person: people(:etienne))
    account = Account.create!(name: "Used household account", owner: nil, group:)
    transaction = Debit.create!(
      amount: 2500, booked_at: Time.current, interest_at: Time.current,
      debitor: account, creditor: accounts(:albert_heijn), category: categories(:groceries)
    )

    assert membership.update(person: people(:michelle))
    assert_equal people(:michelle).id, membership.reload.person_id
    assert_predicate group.reload, :household?
    assert_equal "Debit", transaction.reload.type
    assert_equal 2500, transaction.amount
  end

  test "allows replacing the last household member when the owner has no transactions" do
    group = Group.create!(name: "Unused household group")
    membership = group.group_memberships.create!(person: people(:etienne))
    Account.create!(name: "Unused household account", owner: nil, group:)

    assert membership.update(person: people(:grandma))
    assert_equal people(:grandma).id, membership.reload.person_id
    assert_not_predicate group.reload, :household?
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
