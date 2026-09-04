require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Selenium Manager itself honors SE_CACHE_PATH for where it caches downloaded browsers;
  # follow the same override so this doesn't silently miss a non-default cache location.
  CHROME_CACHE_ROOT = File.join(ENV["SE_CACHE_PATH"].presence || File.expand_path("~/.cache/selenium"), "chrome")

  # Selenium Manager caches each Chrome for Testing build under <platform>/<version>/;
  # the binary's own path below that differs per platform.
  CHROME_LEAF_PATHS = [
    "Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing", # macOS
    "chrome-linux64/chrome",                                                  # Linux
    "chrome-win64/chrome.exe"                                                 # Windows
  ].freeze

  # Deliberately prefers the newest Chrome for Testing build already cached locally over
  # whatever Selenium Manager would otherwise resolve, so tests run without network access.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    binary = ENV["CHROME_BIN"].presence || chrome_binary
    options.binary = binary if binary
  end

  def self.chrome_binary(cache_root: CHROME_CACHE_ROOT)
    version_dirs_newest_first(cache_root).each do |dir|
      binary = chrome_leaf_in(dir)
      return binary if binary
    end

    nil
  end

  def self.version_dirs_newest_first(cache_root)
    Dir.glob("#{cache_root}/*/*")
      .select { |dir| File.directory?(dir) && Gem::Version.correct?(File.basename(dir)) }
      .sort_by { |dir| Gem::Version.new(File.basename(dir)) }
      .reverse
  end
  private_class_method :version_dirs_newest_first

  def self.chrome_leaf_in(version_dir)
    CHROME_LEAF_PATHS.map { |leaf_path| File.join(version_dir, leaf_path) }
      .find { |binary| File.executable?(binary) }
  end
  private_class_method :chrome_leaf_in

  private
    def locale
      @signed_in_user.locale.to_sym
    end

    def sign_in_as(user)
      # Keep system tests independent from external shell env setup.
      ENV["APP_NAME"] ||= "JournalAdministration"

      @signed_in_user = user
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
