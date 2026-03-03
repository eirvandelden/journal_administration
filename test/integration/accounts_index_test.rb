require "test_helper"

class AccountsIndexTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "index shows own and external accounts in separate tables" do
    get accounts_path

    assert_response :success
    assert_select "h2", text: I18n.t("accounts.index.own_accounts")
    assert_select "h2", text: I18n.t("accounts.index.external_accounts")

    assert_select "section:nth-of-type(1) table.accounts tbody td", text: accounts(:checking).name
    assert_select "section:nth-of-type(1) table.accounts tbody td", text: accounts(:savings).name
    assert_select "section:nth-of-type(2) table.accounts tbody td", text: accounts(:albert_heijn).name
    assert_select "section:nth-of-type(2) table.accounts tbody td", text: accounts(:employer).name

    assert_select "section:nth-of-type(1) table.accounts thead th", text: I18n.t("accounts.index.owner")
    assert_select "section:nth-of-type(2) table.accounts thead th", text: I18n.t("accounts.index.owner"), count: 0
  end

  test "own and external pagination params are independent" do
    55.times do |index|
      Account.create!(
        account_number: format("NLOWN%012d", index),
        name: "Pagy Own #{index}",
        owner: :samen
      )

      Account.create!(
        account_number: format("NLEXT%012d", index),
        name: "Pagy External #{index}"
      )
    end

    get accounts_path, params: { own_page: 1, external_page: 1 }
    assert_response :success

    own_items_per_page = css_select("section:nth-of-type(1) table.accounts tbody tr").size
    external_items_per_page = css_select("section:nth-of-type(2) table.accounts tbody tr").size

    own_page_1_number = Account.own.limit(1).pick(:account_number)
    own_page_2_number = Account.own.offset(own_items_per_page).limit(1).pick(:account_number)
    external_page_1_number = Account.external.limit(1).pick(:account_number)
    external_page_2_number = Account.external.offset(external_items_per_page).limit(1).pick(:account_number)

    get accounts_path, params: { own_page: 2, external_page: 1 }

    assert_response :success
    assert own_page_2_number.present?
    assert external_page_2_number.present?

    assert_includes response.body, own_page_2_number
    assert_not_includes response.body, own_page_1_number

    assert_includes response.body, external_page_1_number
    assert_not_includes response.body, external_page_2_number
  end
end
