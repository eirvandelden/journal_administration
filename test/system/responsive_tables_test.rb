require "application_system_test_case"

class ResponsiveTablesTest < ApplicationSystemTestCase
  LAPTOP = [ 1280, 800 ].freeze
  PHONE = [ 390, 844 ].freeze

  setup do
    Transaction.create!(
      type: "Debit", amount: 1234, debitor: accounts(:checking), creditor: accounts(:albert_heijn),
      booked_at: Time.current, note: "a very long description #{'wrapping words ' * 12}and nothing else"
    )
    sign_in_as(users(:member))
  end

  teardown { current_window.resize_to(*SCREEN_SIZE) }

  test "transactions table fits beside the sidebar at laptop width" do
    current_window.resize_to(*LAPTOP)
    visit transactions_url

    assert_no_sideways_scroll
    assert_equal "nowrap", style_of("table.transactions tbody td data", "whiteSpace")
    assert_equal "nowrap", style_of("table.transactions tbody td time", "whiteSpace")
    assert_operator cell_height("table.transactions tbody tr:first-child td:last-child"), :>, 40, "a long note wraps"
  end

  test "transactions table stacks into labelled rows at phone width" do
    current_window.resize_to(*PHONE)
    visit transactions_url

    assert_equal "block", style_of("table.transactions tbody tr", "display")
    assert_equal "block", style_of("table.transactions tbody td", "display")
    assert_equal "\"#{I18n.t('transactions.table.type', locale: locale)}\"",
      style_of("table.transactions tbody td", "content", pseudo: "::before").split(" / ").first
    assert_not_equal "none", style_of("table.transactions thead", "display")
    assert_equal "table", find("table.transactions")["role"]
    assert_equal "columnheader", first("table.transactions th", visible: :all)["role"]
  end

  test "no index page, show page or the dashboard scrolls sideways at phone width" do
    current_window.resize_to(*PHONE)

    pages.each do |url|
      visit url

      assert_no_sideways_scroll url
    end
  end

  test "a long single-word title wraps instead of scrolling sideways at phone width" do
    current_window.resize_to(*PHONE)
    visit receipts_url

    long_word = "Boodschappenfacturenoverzichtsbeheerdersvergadering"
    page.execute_script("document.querySelector('main > header h1').textContent = #{long_word.to_json}")

    assert_no_sideways_scroll "long title"
  end

  private

  def pages
    [
      dashboard_index_url, transactions_url, accounts_url, people_url, groups_url, categories_url, chattels_url,
      budgets_url, appropriations_url, receipts_url, products_url, product_types_url, todo_url,
      account_url(accounts(:checking)), category_url(categories(:supermarket)), budget_url(budgets(:active_budget)),
      appropriation_url(appropriations(:christmas_serena)), receipt_url(receipts(:albert_heijn_friday)),
      product_url(products(:ah_ribbelchips)), product_type_url(product_types(:naturel_chips))
    ]
  end

  def assert_no_sideways_scroll(context = nil)
    widths = page.evaluate_script("[document.documentElement.scrollWidth, document.documentElement.clientWidth]")

    assert_operator widths.first, :<=, widths.last, "#{context} scrolls sideways"
  end

  def style_of(selector, property, pseudo: nil)
    page.evaluate_script(
      "getComputedStyle(document.querySelector(#{selector.to_json}), #{pseudo.to_json})[#{property.to_json}]"
    )
  end

  def cell_height(selector)
    page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().height")
  end
end
