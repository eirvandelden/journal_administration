require "application_system_test_case"

class PeopleTest < ApplicationSystemTestCase
  setup do
    @person = people(:grandpa)
    sign_in_as(users(:member))
  end

  test "dismissing the delete confirm keeps the person" do
    visit edit_person_url(@person)

    dismiss_confirm(/#{@person.name}/) { click_on I18n.t("common.delete_ellipsis", locale: locale) }

    assert_current_path edit_person_path(@person)
    assert Person.exists?(@person.id)
  end

  test "accepting the delete confirm deletes the person" do
    visit edit_person_url(@person)

    accept_confirm(/#{@person.name}/) { click_on I18n.t("common.delete_ellipsis", locale: locale) }

    assert_current_path people_path
    assert_not Person.exists?(@person.id)
  end
end
