require "test_helper"

class OriginBackLinkTest < ActionDispatch::IntegrationTest
  setup do
    users(:member).update!(locale: :nl)
    sign_in_as(users(:member))
    @transaction = transactions(:uncategorized)
  end

  test "categoriseren tile opens the filtered journal with a verwerken back link" do
    get hub_url(:processing)
    tile = css_select("ul.tiles a").map { |link| link["href"] }.find { |href| href.start_with?("/transactions") }

    get tile

    assert_response :success
    assert_select "main > header nav a[href=?]", hub_path(:processing), text: "‹ Verwerken"
    assert_select "tbody a[href*='from=processing']"
  end

  test "origin survives show edit and save" do
    list = transactions_path(filter: :no_category, from: :processing)

    get transaction_url(@transaction, from: :processing)

    assert_select "main > header nav a[href=?]", list, text: "‹ Categoriseren"
    assert_select "main > header nav a[href=?]", edit_transaction_path(@transaction, from: :processing)

    get edit_transaction_url(@transaction, from: :processing)

    assert_select "form input[name=from][value=processing]"
    assert_select "a[href=?]", "#{polymorphic_path(@transaction)}?from=processing",
      text: I18n.t("common.cancel", locale: :nl)

    patch transaction_url(@transaction), params: { from: "processing", transaction: { note: "kept" } }

    assert_redirected_to "#{polymorphic_path(@transaction)}?from=processing"
    follow_redirect!

    assert_select "main > header nav a[href=?]", list, text: "‹ Categoriseren"
  end

  test "delete from a verwerken flow lands on verwerken" do
    delete transaction_url(@transaction), params: { from: "processing" }

    assert_redirected_to hub_path(:processing)
  end

  test "transaction without origin links back to the journal" do
    get transaction_url(@transaction)

    assert_select "main > header nav a[href=?]", transactions_path, text: "‹ Journaal"
  end

  test "an unknown origin is ignored" do
    get transaction_url(@transaction, from: "nonsense")

    assert_select "main > header nav a[href=?]", transactions_path, text: "‹ Journaal"
  end

  test "adding a split keeps the origin" do
    post transaction_transaction_splits_url(@transaction), params: {
      from: "processing", transaction_split: { category_id: categories(:groceries).id, amount: "1,00" }
    }

    assert_redirected_to edit_transaction_path(@transaction, from: :processing)
  end

  test "edit page forms carry the origin" do
    get edit_transaction_url(@transaction, from: :processing)

    assert_select "section form input[name=from][value=processing]", minimum: 2
  end

  test "products receipts chattels and categories round trip to their tile list" do
    {
      products_path(filter: :unclassified, from: :shopping) => [ product_path(products(:ah_ribbelchips)), "Producten" ],
      receipts_path(filter: :without_payment, from: :shopping) =>
        [ receipt_path(receipts(:albert_heijn_friday)), "Facturen" ],
      chattels_path(filter: :warranty_ending, from: :records) => [ chattel_path(chattels(:one)), "Bezittingen" ],
      categories_path(from: :setup) => [ category_path(categories(:housing)), "Categorieën" ]
    }.each do |list, (record, label)|
      get "#{record}#{list[/from=\w+/] ? "?#{list[/from=\w+/]}" : ""}"

      assert_select "main > header nav a[href=?]", list, text: "‹ #{label}"
    end
  end

  test "a record without an origin keeps its own index as the back link" do
    get chattel_url(chattels(:one))

    assert_select "main > header nav a[href=?]", chattels_path, text: "‹ Bezittingen"
  end

  test "deleting a chattel opened from a beheer tile lands on the beheer landing page" do
    delete chattel_url(chattels(:one)), params: { from: "records" }

    assert_redirected_to hub_path(:records)
  end
end
