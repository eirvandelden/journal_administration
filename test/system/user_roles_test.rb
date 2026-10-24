require "application_system_test_case"

class UserRolesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @member = users(:member)
    sign_in_as(@admin)
  end

  test "an administrator makes a member an administrator by ticking the role box" do
    visit users_url

    find("label[for='#{dom_id(@member, :role)}']").click

    assert_selector "label[for='#{dom_id(@member, :role)}']",
      text: I18n.t("users.user.role_administrator", locale: locale)
    assert_predicate @member.reload, :administrator?
  end

  test "an administrator makes another administrator a member by unticking the role box" do
    @member.update!(role: :administrator)
    visit users_url

    find("label[for='#{dom_id(@member, :role)}']").click

    assert_selector "label[for='#{dom_id(@member, :role)}']",
      text: I18n.t("users.user.role_member", locale: locale)
    assert_predicate @member.reload, :member?
  end

  private

  def dom_id(record, prefix)
    ActionView::RecordIdentifier.dom_id(record, prefix)
  end
end
