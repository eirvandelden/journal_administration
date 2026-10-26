require "test_helper"

class Assistant::ListUnclassifiedProductsTest < ActiveSupport::TestCase
  test "lists the products that lack a brand or a type" do
    text = answer

    assert_includes text, "#{products(:andrelon_shampoo).id}: Andrelon shampoo (no brand, no type)"
    assert_not_includes text, products(:ah_ribbelchips).name
  end

  test "lists the products in two queries however many there are" do
    20.times { |number| Product.create!(name: "Onbekend #{number}", product_type: product_types(:naturel_chips)) }

    queries = []
    counter = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { answer }

    assert_equal 2, queries.size
  end

  test "says when the list was cut short" do
    now = Time.current
    rows = (Assistant::ListUnclassifiedProducts::HIGHEST_COUNT + 1).times.map do |number|
      { name: "Weinig #{number}", normalized_name: "weinig #{number}", created_at: now, updated_at: now }
    end
    Product.insert_all(rows)

    assert_match(/Showing 250 of \d+ products/, answer)
  end

  private

  def answer = Assistant::ListUnclassifiedProducts.call(server_context: nil).content.first[:text]
end
