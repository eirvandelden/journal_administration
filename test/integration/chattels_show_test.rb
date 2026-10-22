require "test_helper"

class ChattelsShowTest < ActionDispatch::IntegrationTest
  setup do
    @chattel = chattels(:one)
    @member = users(:member)
  end

  test "show page lists the fields as a description list" do
    sign_in_as(@member)

    get chattel_url(@chattel)

    assert_response :success
    assert_select "main dl dt", text: Chattel.human_attribute_name(:name)
    assert_select "main dl dd", text: @chattel.name
    assert_select "main form", count: 0
  end

  test "show includes navigation to edit page" do
    sign_in_as(@member)

    get chattel_url(@chattel)

    assert_response :success
    assert_select "a[href='#{edit_chattel_path(@chattel)}']", text: I18n.t("common.edit")
  end

  test "show page has no delete button" do
    sign_in_as(@member)

    get chattel_url(@chattel)

    assert_select "button.button-danger", count: 0
    assert_select "input[name=_method][value=delete]", count: 0
  end

  test "edit page ends in an action row with Verwijderen…" do
    sign_in_as(@member)

    get edit_chattel_url(@chattel)

    assert_select "form > footer button.button-danger[form='#{dom_id(@chattel, :delete)}']"
    assert_select "form##{dom_id(@chattel, :delete)}[action='#{chattel_path(@chattel)}']"
  end

  test "index does not include destroy button" do
    sign_in_as(@member)

    get chattels_url

    assert_response :success
    assert_select "button", text: I18n.t("common.destroy"), count: 0
  end

  test "index has a title bar with + Nieuw and rows that open the chattel" do
    sign_in_as(@member)

    get chattels_url

    assert_select "main > header > h1", count: 1
    assert_select "main > header nav a[href='#{new_chattel_path}']", text: I18n.t("common.new")
    assert_select "tbody td a[href='#{chattel_path(@chattel)}']"
    assert_select "tbody td a[href='#{edit_chattel_path(@chattel)}']", count: 0
  end
end
