require "test_helper"

class GroupsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "a user edits Samen members and assigns Samen to an account" do
    post people_path, params: { person: { name: "Alex", household: true } }

    assert_response :redirect
    alex = Person.find_by!(name: "Alex")

    patch group_path(groups(:samen)), params: {
      group: { name: "Samen", person_ids: [ people(:etienne).id, people(:michelle).id, alex.id ] }
    }

    assert_redirected_to group_path(groups(:samen))
    get group_path(groups(:samen))

    assert_select "body", text: /Alex/

    account = accounts(:jumbo)
    patch account_path(account), params: { account: { group_id: groups(:samen).id } }

    assert_redirected_to account_path(account)
    assert_includes groups(:samen).people, alex
    assert_equal groups(:samen), account.reload.group
  end

  test "refuses to remove the final household member from a used group through update" do
    group = groups(:samen)
    memberships = group.group_memberships.order(:id).pluck(:id, :person_id)
    history = Transaction.order(:id).pluck(:id, :type, :amount)

    patch group_path(group), params: { group: { name: group.name, person_ids: [ people(:grandma).id ] } }

    assert_redirected_to group_path(group)
    assert_predicate flash[:alert], :present?
    assert_equal memberships, group.group_memberships.order(:id).pluck(:id, :person_id)
    assert_equal history, Transaction.order(:id).pluck(:id, :type, :amount)
  end

  test "refuses to remove a grouped account owner's household status through update" do
    person = Person.create!(name: "Alex", household: true)
    group = Group.create!(name: "Alex household")
    membership = GroupMembership.create!(group:, person:)
    account = Account.create!(name: "Alex joint account", group:)
    transaction = Transaction.create!(debitor: account, creditor: accounts(:unknown), amount: 10)
    history = [ transaction.id, transaction.type, transaction.amount ]

    patch person_path(person), params: { person: { name: person.name, household: false } }

    assert_redirected_to person_path(person)
    assert_predicate flash[:alert], :present?
    assert_predicate person.reload, :household?
    assert_equal [ membership.id, person.id ], group.group_memberships.pluck(:id, :person_id).sole
    assert_equal history, [ transaction.reload.id, transaction.type, transaction.amount ]
  end
end
