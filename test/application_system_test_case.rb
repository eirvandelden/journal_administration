require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  SCREEN_SIZE = [ 1400, 1400 ].freeze
  CI_ARGUMENTS = %w[ --no-sandbox --disable-dev-shm-usage --no-first-run --disable-gpu ].freeze

  # Rails' system testing only knows Chrome and Firefox, so Edge needs its own Capybara driver.
  # Selenium Manager resolves the msedgedriver that matches the installed Edge.
  # On CI the Ubuntu runner blocks the Chromium sandbox and has a small /dev/shm, so Edge exits or hangs at start.
  def self.edge_options(binary: ENV["EDGE_BIN"].presence, ci: ENV["CI"].present?)
    Selenium::WebDriver::Edge::Options.new.tap do |options|
      options.add_argument("--headless")
      CI_ARGUMENTS.each { |argument| options.add_argument(argument) } if ci
      options.binary = binary if binary
    end
  end

  # One log file per process, so parallel workers do not overwrite each other.
  def self.log_path(name, pid: Process.pid)
    Rails.root.join("tmp/screenshots/#{name}-#{pid}.log").to_s
  end

  # CI evidence for intermittent hangs: msedgedriver's verbose log lands in tmp/screenshots, which CI uploads.
  def self.edge_service(ci: ENV["CI"].present?)
    return unless ci

    Selenium::WebDriver::Edge::Service.new(log: log_path("msedgedriver"), args: %w[ --verbose ])
  end

  def self.edge_driver(app, driver_class: Capybara::Selenium::Driver, options: edge_options, service: edge_service)
    arguments = { browser: :edge, options: options, service: service }.compact
    driver_class.new(app, **arguments).tap do |driver|
      driver.browser.manage.window.size = Selenium::WebDriver::Dimension.new(*SCREEN_SIZE)
    end
  end

  Capybara.register_driver(:headless_edge) do |app|
    if ENV["CI"].present?
      FileUtils.mkdir_p(Rails.root.join("tmp/screenshots"))
      Selenium::WebDriver.logger.level = :debug
      Selenium::WebDriver.logger.output = log_path("selenium")
    end
    edge_driver(app)
  end

  driven_by :headless_edge

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
