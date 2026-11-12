require "application_system_test_case"

# The rail, hub column and title bar as mvpa.css lays them out at phone width and in a narrow window
class NavigationHubsLayoutTest < ApplicationSystemTestCase
  PHONE = [ 390, 844 ].freeze
  NARROW = [ 900, 800 ].freeze
  HUBS = %w[Overzicht Verwerken Plannen Administratie Boodschappen].freeze

  setup do
    users(:member).update!(locale: :nl)
    sign_in_as(users(:member))
  end

  teardown { current_window.resize_to(*SCREEN_SIZE) }

  test "phone tab bar and avatar only on overzicht" do
    current_window.resize_to(*PHONE)
    visit dashboard_index_url

    assert_equal HUBS, all("nav.rail > ul > li").map { |item| item.text.split.last }
    assert_selector "nav.rail > search", visible: :hidden
    assert_operator rail_bottom, :>=, viewport_height - 1, "the tab bar sits at the bottom"
    assert_selector "main > header nav > details > summary[aria-label='#{users(:member).name}']"

    visit hub_url(:processing)

    assert_no_selector "main > header nav details", visible: :all
    assert_selector "main > header nav > search > button"
    assert_selector "body > header > nav.rail + nav", visible: :hidden
  end

  test "narrow window hides hub column and keeps landing page" do
    current_window.resize_to(*NARROW)
    visit transactions_url

    assert_selector "body > header > nav.rail + nav", visible: :hidden

    within("nav.rail") { click_link "Verwerken" }

    assert_current_path hub_path(:processing)
    assert_selector "main > nav a", text: "Consolideren"
  end

  test "a tile shows its label above its text at every width" do
    [ SCREEN_SIZE, PHONE ].each do |size|
      current_window.resize_to(*size)
      visit hub_url(:processing)

      assert_equal [ true ] * 5, text_below_label, "at #{size.join('x')}"
    end
  end

  private
    # For each landing tile: the text after the label starts below the label
    def text_below_label
      page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("main > nav a")).map((tile) => {
          const label = tile.querySelector("strong")
          const range = document.createRange()
          range.setStartAfter(label)
          range.setEnd(tile, tile.childNodes.length)
          const tops = Array.from(range.getClientRects()).filter((rect) => rect.width > 0).map((rect) => rect.top)
          return Math.min(...tops) >= label.getBoundingClientRect().bottom - 1
        })
      JS
    end

    def rail_bottom
      page.evaluate_script("document.querySelector('nav.rail').getBoundingClientRect().bottom")
    end

    def viewport_height
      page.evaluate_script("window.innerHeight")
    end
end
