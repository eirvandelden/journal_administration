require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SCREEN_SIZE = [ 1400, 1400 ].freeze

  # Rails' system testing only knows Chrome and Firefox, so Edge needs its own Capybara driver.
  # Selenium Manager resolves the msedgedriver that matches the installed Edge.
  def self.edge_options(binary: ENV["EDGE_BIN"].presence)
    Selenium::WebDriver::Edge::Options.new.tap do |options|
      options.add_argument("--headless")
      options.binary = binary if binary
    end
  end

  def self.edge_driver(app, driver_class: Capybara::Selenium::Driver, options: edge_options)
    driver_class.new(app, browser: :edge, options: options).tap do |driver|
      driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*SCREEN_SIZE)
    end
  end

  # Headless Edge hangs or dies in about a quarter of CI runs, so CI keeps the stock headless Chrome driver.
  def self.driver_name(ci: ENV["CI"].present?)
    ci ? :selenium : :headless_edge
  end

  Capybara.register_driver(:headless_edge) { |app| edge_driver(app) }

  if driver_name == :selenium
    driven_by :selenium, using: :headless_chrome, screen_size: SCREEN_SIZE
  else
    driven_by :headless_edge
  end

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
