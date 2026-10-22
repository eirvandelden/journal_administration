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

  test "the people pages load" do
    get people_path

    assert_response :success
    assert_select "td a[href='#{person_path(people(:etienne))}']", text: "Etienne"

    get new_person_path

    assert_response :success
    assert_select "form input[name='person[name]']"

    get edit_person_path(people(:etienne))

    assert_response :success
    assert_select "form input[name='person[name]'][value='Etienne']"
  end

  test "deleting a person that owns an account is refused" do
    assert_no_difference "Person.count" do
      delete person_path(people(:etienne))
    end

    assert_predicate flash[:alert], :present?
  end

  test "deleting a person with an appropriation is refused" do
    assert_no_difference "Person.count" do
      delete person_path(people(:chiara))
    end

    assert_predicate flash[:alert], :present?
  end

  test "deleting a person who belongs to a group is refused" do
    assert_no_difference [ "Person.count", "GroupMembership.count" ] do
      delete person_path(people(:michelle))
    end

    assert_predicate flash[:alert], :present?
  end

  test "deleting an unused person removes it" do
    assert_difference "Person.count", -1 do
      delete person_path(people(:grandpa))
    end

    assert_redirected_to people_path
  end

  test "the account form offers managed owners and assigns a person" do
    account = Account.create!(name: "Fresh account")

    get edit_account_path(account)

    assert_select "select[name='account[managed_owner]'] option[value='person_#{people(:etienne).id}']"
    assert_select "select[name='account[managed_owner]'] option[value='group_#{groups(:samen).id}']"

    patch account_path(account), params: { account: { managed_owner: "person_#{people(:etienne).id}" } }

    assert_equal people(:etienne), account.reload.person
    assert_nil account.group
  end

  test "submitting an empty managed owner clears the owner" do
    account = Account.create!(name: "Owned account", person: people(:etienne))

    patch account_path(account), params: { account: { managed_owner: "" } }

    assert_nil account.reload.person
    assert_predicate account, :external?
  end

  test "submitting an unknown managed owner shows an error instead of failing" do
    account = Account.create!(name: "Fresh account")

    patch account_path(account), params: { account: { managed_owner: "person_99999" } }

    assert_response :unprocessable_entity
    assert_nil account.reload.person_id
  end

  test "the account form explains a refused owner change on an account with transactions" do
    account = accounts(:checking)

    patch account_path(account), params: { account: { managed_owner: "" } }

    assert_response :unprocessable_entity
    assert_select "aside[role=alert] li",
      text: /cannot change its household ownership because it has transactions/
    assert_equal groups(:samen), account.reload.group
  end

  test "show page has no delete button" do
    get person_path(people(:etienne))

    assert_select "button.button-danger", count: 0
    assert_select "input[name=_method][value=delete]", count: 0
  end

  test "edit page ends in an action row with Verwijderen…" do
    person = people(:grandpa)

    get edit_person_path(person)

    assert_select "form > footer button.button-danger[form='#{dom_id(person, :delete)}']"
    assert_select "form##{dom_id(person, :delete)}[action='#{person_path(person)}']"
  end

  test "saving a person without a name shows the error in an alert" do
    patch person_path(people(:grandma)), params: { person: { name: "", household: false } }

    assert_select "form > aside[role=alert] li"
  end

  test "a refused delete returns to the edit page with the reason" do
    delete person_path(people(:etienne))

    assert_redirected_to edit_person_path(people(:etienne))
    assert_predicate flash[:alert], :present?
  end

  test "the index rows hold no action column and the name opens the person" do
    get people_path

    assert_select "main > header > h1", count: 1
    assert_select "main > header nav a[href='#{new_person_path}']", text: I18n.t("common.new")
    assert_select "tbody td a", count: Person.count
  end
end
