require "test_helper"

class CategoriesIndexTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    sign_in_as(@member)
  end

  test "index renders one section per parent category" do
    get categories_path

    assert_response :success
    assert_select "h2", text: I18n.t("categories.index.root_categories")
    assert_select "h2", text: categories(:groceries).name
    assert_select "h2", text: categories(:housing).name
    assert_select "h2", text: categories(:income).name
  end

  test "index renders the root section first" do
    get categories_path

    assert_response :success

    headings = Nokogiri::HTML5(response.body).css("h2").map(&:text)

    assert_equal [
      I18n.t("categories.index.root_categories"),
      categories(:groceries).name,
      categories(:housing).name,
      categories(:income).name
    ], headings
  end

  test "index renders root categories under the root section" do
    get categories_path

    assert_response :success
    assert_select "article" do
      assert_select "h2", text: I18n.t("categories.index.root_categories")
      assert_select "td", text: categories(:groceries).name
      assert_select "td", text: categories(:housing).name
      assert_select "td", text: categories(:income).name
      assert_select "td", text: categories(:transfer).name
    end
  end

  test "index renders child categories under their parent section" do
    get categories_path

    assert_response :success
    assert_select "article", count: 5
    assert_select "td", text: categories(:bakery).name
    assert_select "td", text: categories(:supermarket).name
    assert_select "td", text: categories(:rent).name
    assert_select "td", text: categories(:salary).name
  end

  test "index does not show parent column per row" do
    get categories_path

    assert_response :success

    header_rows = Nokogiri::HTML5(response.body).css("table.categories thead tr")

    header_rows.each do |row|
      assert_equal [ I18n.t("categories.index.name") ], row.css("th").map { |cell| cell.text.strip }
    end
  end

  test "index has a title bar with + Nieuw and rows that open the category" do
    get categories_path

    assert_select "main > header > h1", count: 1
    assert_select "main > header nav a[href='#{new_category_path}']", text: I18n.t("common.new")
    assert_select "tbody td a[href='#{category_path(categories(:supermarket))}']", text: categories(:supermarket).name
  end
end
