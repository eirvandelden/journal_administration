require "test_helper"

class SearchesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:member)
    sign_in_as(@user)
  end

  # -- authentication ---------------------------------------------------------

  test "GET /searches redirects when not signed in" do
    delete session_url
    get searches_url

    assert_redirected_to new_session_url
  end

  # -- index ------------------------------------------------------------------

  test "GET /searches returns success" do
    get searches_url

    assert_response :success
  end

  test "GET /searches renders a turbo frame" do
    get searches_url

    assert_select "turbo-frame#search-results"
  end

  test "GET /searches with blank query shows no results message" do
    get searches_url, params: { q: "" }

    assert_response :success
    assert_select "turbo-frame#search-results p", count: 0
  end

  test "GET /searches with query shows matching account" do
    get searches_url, params: { q: "Gezamenlijke" }

    assert_response :success
    assert_select "a", text: /Gezamenlijke/
  end

  test "GET /searches with query shows matching chattel" do
    get searches_url, params: { q: "Laptop" }

    assert_response :success
    assert_select "a", text: /Laptop/
  end

  test "GET /searches with unmatched query shows no results message" do
    get searches_url, params: { q: "xyzzy_nonexistent_42" }

    assert_response :success
    assert_select "p", text: I18n.t("search.no_results")
  end

  test "GET /searches with Turbo-Frame header returns success" do
    get searches_url, params: { q: "Laptop" }, headers: { "Turbo-Frame" => "search-results" }

    assert_response :success
  end
end
