require "test_helper"

class DeleteConfirmAfterRejectedSaveTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "person confirm names the stored name after a rejected save" do
    person = people(:grandma)

    patch person_path(person), params: { person: { name: "" } }

    assert_stored_name_in_confirm person.name
  end

  test "group confirm names the stored name after a rejected save" do
    group = groups(:samen)

    patch group_path(group), params: { group: { name: "" } }

    assert_stored_name_in_confirm group.name
  end

  test "account confirm names the stored name after a rejected save" do
    account = accounts(:checking)

    taken_number = accounts(:savings).numbers.first

    patch account_path(account),
      params: { account: { name: "Unsaved", account_numbers_attributes: { "0" => { number: taken_number } } } }

    assert_select "form > aside[role=alert] li"

    assert_stored_name_in_confirm account.name
  end

  test "category confirm names the stored name after a rejected save" do
    category = categories(:groceries)

    patch category_path(category), params: { category: { name: "Unsaved", direction: "" } }

    assert_stored_name_in_confirm category.name
  end

  test "chattel confirm names the stored name after a rejected save" do
    chattel = chattels(:one)

    patch chattel_path(chattel), params: { chattel: { name: "" } }

    assert_stored_name_in_confirm chattel.name
  end

  private

  def assert_stored_name_in_confirm(name)
    assert_select "button[data-turbo-confirm]" do |buttons|
      assert_includes buttons.first["data-turbo-confirm"], %("#{name}")
    end
  end
end
