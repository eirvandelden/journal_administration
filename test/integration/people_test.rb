require "test_helper"

class PeopleTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "a user creates a household person and assigns that person to an account" do
    post people_path, params: { person: { name: "Alex", household: true } }

    person = Person.find_by!(name: "Alex")
    account = accounts(:savings)
    patch account_path(account), params: { account: { person_id: person.id } }

    assert_equal person, account.reload.person
    assert_predicate account, :household_owned?
  end

  test "a failed update with a blank name renders the edit form again" do
    patch person_path(people(:grandma)), params: { person: { name: "", household: false } }

    assert_response :unprocessable_entity
    assert_select "form input[name='person[name]']"
    assert_equal "Grandma", people(:grandma).reload.name
  end

  test "a failed update keeps the submitted value in the edit form" do
    patch person_path(people(:grandma)), params: { person: { name: "Michelle", household: false } }

    assert_response :unprocessable_entity
    assert_select "form input[name='person[name]'][value='Michelle']"
  end
end
