require "application_system_test_case"

class SearchDialogTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)
    sign_in_as(@user)
  end

  test "search button opens the dialog" do
    visit root_url

    click_button I18n.t("search.open")

    assert_equal true, page.evaluate_script("document.getElementById('search-dialog').open")
  end

  test "keyboard shortcut does not crash when dialog is already open" do
    visit root_url

    page.execute_script(<<~JS)
      const dialog = document.getElementById("search-dialog")
      dialog.showModal()
      window.searchDialogShowModalCalls = 0
      dialog.showModal = function() {
        window.searchDialogShowModalCalls += 1
      }
    JS

    page.execute_script(<<~JS)
      document.dispatchEvent(new KeyboardEvent("keydown", {
        key: "k",
        ctrlKey: true,
        bubbles: true
      }))
    JS

    assert_equal true, page.evaluate_script("document.getElementById('search-dialog').open")
    assert_equal 0, page.evaluate_script("window.searchDialogShowModalCalls")
  end
end
