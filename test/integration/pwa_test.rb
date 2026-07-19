require "test_helper"

# PWA installability is greenfield for JA (no manifest/service-worker/icons
# existed before this phase) — verify the engine's mounted endpoints actually
# render against JA's real app_name/brand_color/icon files.
class PwaTest < ActionDispatch::IntegrationTest
  test "manifest renders JA's app name, brand color, and icon files" do
    get manifest_path

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal "JournalAdministration", body["name"]
    assert_equal "#0068c9", body["theme_color"]
    icon_paths = body["icons"].map { |icon| icon["src"] }
    assert_includes icon_paths, "/icon.svg"
    assert_includes icon_paths, "/icon-192.png"
    assert_includes icon_paths, "/icon-512.png"
    assert_includes icon_paths, "/icon-mask-512.png"
  end

  test "every advertised manifest icon file actually exists in public/" do
    get manifest_path
    icons = JSON.parse(response.body)["icons"]

    icons.each do |icon|
      assert Rails.root.join("public#{icon['src']}").exist?, "missing icon file: #{icon['src']}"
      assert Rails.root.join("public#{icon['src']}").size > 0, "icon file is empty: #{icon['src']}"
    end
  end

  test "service worker renders as JavaScript" do
    get service_worker_path

    assert_response :success
    assert_equal "application/javascript; charset=utf-8", response.media_type + "; charset=" + response.charset
  end

  test "application layout advertises the apple touch icon and manifest" do
    sign_in_as(users(:member))
    get root_path

    assert_response :success
    assert_select "link[rel=manifest]"
    assert_select "link[rel='apple-touch-icon']"
  end

  # The engine's own login layout doesn't render _pwa_meta — JA overrides
  # app/views/layouts/login.html.erb locally (host view paths win over the
  # engine's) to add it, without touching the gem.
  test "login layout advertises the manifest too" do
    get new_session_path

    assert_response :success
    assert_select "link[rel=manifest]"
  end
end
