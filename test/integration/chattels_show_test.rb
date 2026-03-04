require "test_helper"

class ChattelsShowTest < ActionDispatch::IntegrationTest
  setup do
    @chattel = chattels(:one)
    @member = users(:member)
  end

  test "show renders read-only form without save action" do
    sign_in_as(@member)

    get chattel_url(@chattel)

    assert_response :success
    assert_select "form"
    assert_select "input[type=submit][value='Save']", count: 0
    assert_select "input[name='chattel[name]'][disabled]"
    assert_select "textarea[name='chattel[notes]'][disabled]"
  end

  test "show includes navigation to edit page" do
    sign_in_as(@member)

    get chattel_url(@chattel)

    assert_response :success
    assert_select "a[href='#{edit_chattel_path(@chattel)}']", text: I18n.t("common.edit")
  end
end
