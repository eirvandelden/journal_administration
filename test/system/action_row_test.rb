require "application_system_test_case"

class ActionRowTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:albert_heijn)
    sign_in_as(users(:member))
  end

  test "Verwijderen… stands apart on the left and Opslaan is rightmost" do
    visit edit_account_url(@account)

    rects = row_rects
    delete, cancel, save = rects.values_at("delete", "cancel", "save")

    assert_operator delete["right"], :<, cancel["left"]
    assert_operator cancel["right"], :<=, save["left"] + 1
    assert_operator rects["footer"]["right"] - save["right"], :<=, 24
    assert_operator cancel["left"] - delete["right"], :>, 100, "Verwijderen… sits apart from Annuleren"
  end

  test "new page action row sits on the right without Verwijderen…" do
    visit new_account_url

    assert_no_button I18n.t("common.delete_ellipsis", locale: locale)
    rects = row_rects
    save = rects["save"]

    assert_operator rects["footer"]["right"] - save["right"], :<=, 24
    assert_operator rects["cancel"]["left"] - rects["footer"]["left"], :>, 100, "Annuleren sits on the right"
  end

  test "pressing Return in the account name saves the account" do
    visit edit_account_url(@account)

    fill_in "account_name", with: "Return Saved"
    find_by_id("account_name").send_keys(:return)

    assert_text I18n.t("accounts.update.success", locale: locale)
    assert_equal "Return Saved", @account.reload.name
  end

  test "Annuleren has a border and a different background from Opslaan" do
    visit edit_account_url(@account)

    cancel = find("form > footer a[role=button].button-secondary")
    styles = page.evaluate_script(<<~JS, cancel.native)
      (function(link) {
        const save = document.querySelector("form > footer input[type=submit]")
        const a = getComputedStyle(link), b = getComputedStyle(save)
        return { border: a.borderTopWidth, cancelBg: a.backgroundColor, saveBg: b.backgroundColor }
      })(arguments[0])
    JS

    assert_not_equal "0px", styles["border"]
    assert_not_equal styles["saveBg"], styles["cancelBg"]
  end

  private

  def row_rects
    page.evaluate_script(<<~JS)
      (function() {
        const rect = (el) => { const r = el.getBoundingClientRect(); return { left: r.left, right: r.right } }
        const footer = document.querySelector("form > footer")
        const out = { footer: rect(footer), cancel: rect(footer.querySelector("a")), save: rect(footer.querySelector("input[type=submit]")) }
        const del = footer.querySelector("button")
        if (del) out.delete = rect(del)
        return out
      })()
    JS
  end
end
