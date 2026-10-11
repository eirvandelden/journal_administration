require "test_helper"

class GroupsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "a user edits Samen members and assigns Samen to an account" do
    post people_path, params: { person: { name: "Alex", household: true } }
    alex = Person.find_by!(name: "Alex")

    patch group_path(groups(:samen)), params: {
      group: { name: "Samen", person_ids: [ people(:etienne).id, people(:michelle).id, alex.id ] }
    }
    get group_path(groups(:samen))

    assert_select "body", text: /Alex/

    patch account_path(accounts(:checking)), params: { account: { group_id: groups(:samen).id } }

    assert_includes groups(:samen).people, alex
    assert_equal groups(:samen), accounts(:checking).reload.group
  end
end
