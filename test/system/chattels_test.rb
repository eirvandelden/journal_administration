require "application_system_test_case"

class ChattelsTest < ApplicationSystemTestCase
  setup do
    @chattel = chattels(:one)
    @user = users(:member)
    @locale = @user.locale.to_sym
    sign_in_as(@user)
  end

  test "visiting the index" do
    visit chattels_url
    assert_link I18n.t("chattels.index.new_chattel", locale: @locale)
  end

  test "should create chattel" do
    visit chattels_url
    click_on I18n.t("chattels.index.new_chattel", locale: @locale)

    fill_in "chattel_name", with: "System Test Chattel"
    click_on I18n.t("common.save", locale: @locale)

    assert_text "Chattel was successfully created"
    click_on I18n.t("common.back", locale: @locale)
  end

  test "should update Chattel" do
    visit chattel_url(@chattel)
    click_on I18n.t("common.edit", locale: @locale), match: :first

    fill_in "chattel_name", with: "#{@chattel.name} updated"
    click_on I18n.t("common.save", locale: @locale)

    assert_text "Chattel was successfully updated"
    click_on I18n.t("common.back", locale: @locale)
  end

  test "should destroy Chattel" do
    visit chattels_url

    assert_difference("Chattel.count", -1) do
      accept_confirm do
        click_on I18n.t("common.destroy", locale: @locale), match: :first
      end
      assert_text "Chattel was successfully destroyed"
    end
  end
end
