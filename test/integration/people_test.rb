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
end
