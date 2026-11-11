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
    assert_no_selector "nav.rail > search"
    assert_operator rail_bottom, :>=, viewport_height - 1, "the tab bar sits at the bottom"
    assert_selector "main > header nav > details > summary[aria-label='#{users(:member).name}']"

    visit hub_url(:processing)

    assert_no_selector "main > header nav details", visible: :all
    assert_selector "main > header nav > search > button"
    assert_no_selector "body > header > nav.rail + nav"
  end

  test "narrow window hides hub column and keeps landing page" do
    current_window.resize_to(*NARROW)
    visit transactions_url

    assert_no_selector "body > header > nav.rail + nav"

    within("nav.rail") { click_link "Verwerken" }

    assert_current_path hub_path(:processing)
    assert_selector "main > nav a", text: "Categoriseren"
  end

  private
    def rail_bottom
      page.evaluate_script("document.querySelector('nav.rail').getBoundingClientRect().bottom")
    end

    def viewport_height
      page.evaluate_script("window.innerHeight")
    end
end
