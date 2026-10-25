require "test_helper"

class AppropriationsHelperTest < ActionView::TestCase
  setup { travel_to Date.new(2026, 10, 25) }

  test "groups options per person by name" do
    assert_equal %w[Chiara Cosimo Etienne Serena], options.css("optgroup").map { |group| group["label"] }
  end

  test "labels options by purpose and year" do
    etienne = options.css("optgroup[label=Etienne] option").map(&:text)

    assert_equal [ "Birthday 2026", "Christmas 2026" ], etienne
  end

  test "offers only this year's appropriations" do
    assert_not_includes options.css("option").map(&:text), "Birthday 2027"
    assert_equal 5, options.css("option").size
  end

  test "keeps the selected appropriation from another year" do
    selected = appropriations(:birthday_chiara_next_year)

    chiara = options(selected:).css("optgroup[label=Chiara] option")

    assert_equal [ "Birthday 2027", "Sinterklaas 2026" ], chiara.map(&:text)
    assert_equal [ "Birthday 2027" ], chiara.css("[selected]").map(&:text)
  end

  test "marks nothing selected without a selection" do
    assert_empty options.css("option[selected]")
  end

  test "loads the options with at most two queries" do
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { grouped_appropriation_options }

    assert_operator queries, :<=, 2
  end

  private

  def options(selected: nil)
    Nokogiri::HTML5.fragment(grouped_appropriation_options(selected:))
  end
end
