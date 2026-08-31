require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  CHROME_CACHE_ROOT = File.expand_path("~/.cache/selenium/chrome")

  # Chrome for Testing binary names Selenium Manager caches under a version directory,
  # by platform.
  CHROME_LEAF_PATHS = [
    "Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing", # macOS
    "chrome-linux64/chrome",                                                  # Linux
    "chrome-win64/chrome.exe"                                                 # Windows
  ].freeze

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    binary = ENV["CHROME_BIN"].presence || chrome_binary
    options.binary = binary if binary
  end

  # Finds the newest Chrome for Testing binary Selenium Manager has already cached locally.
  #
  # Falls back to this when Selenium Manager can't resolve or download a browser itself
  # (e.g. no network access), but a compatible one is already sitting in its own cache.
  #
  # @return [String, nil]
  def self.chrome_binary(cache_root: CHROME_CACHE_ROOT)
    version_dirs = Dir.glob("#{cache_root}/*/*").select { |dir| File.directory?(dir) }
    newest_first = version_dirs.sort_by { |dir| Gem::Version.new(File.basename(dir)) }.reverse

    newest_first.each do |version_dir|
      CHROME_LEAF_PATHS.each do |leaf_path|
        binary = File.join(version_dir, leaf_path)
        return binary if File.executable?(binary)
      end
    end

    nil
  end

  private
    def sign_in_as(user)
      # Keep system tests independent from external shell env setup.
      ENV["APP_NAME"] ||= "JournalAdministration"

      @locale = user.locale.to_sym

      session = user.sessions.first || user.sessions.start!(user_agent: "SystemTest", ip_address: "127.0.0.1")
      signed_token = signed_cookie_value(:session_token, session.token)

      # A page must be loaded before Selenium can add cookies for the host.
      visit root_url
      page.driver.browser.manage.add_cookie(name: "session_token", value: signed_token, path: "/")
      visit root_url
    end

    def signed_cookie_value(name, value)
      request = ActionDispatch::TestRequest.create
      cookie_jar = ActionDispatch::Cookies::CookieJar.build(request, {})
      cookie_jar.signed[name] = value
      cookie_jar[name]
    end
end
