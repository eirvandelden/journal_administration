require "test_helper"
require "application_system_test_case"

class ApplicationSystemTestCaseTest < ActiveSupport::TestCase
  class FakeDriver
    Window = Struct.new(:dimension) do
      def size=(dimension)
        self.dimension = dimension
      end
    end
    Manage = Struct.new(:window)
    Browser = Struct.new(:manage)

    class << self
      attr_reader :last
    end

    attr_reader :app, :arguments, :window

    def self.new(app, **arguments)
      @last = super().tap { |driver| driver.setup(app, arguments) }
    end

    def setup(app, arguments)
      @app = app
      @arguments = arguments
      @window = Window.new
    end

    def browser
      Browser.new(Manage.new(window))
    end
  end

  test "system tests are driven by headless Edge" do
    assert_equal :headless_edge, ApplicationSystemTestCase.driver.name
    assert Capybara.drivers[:headless_edge]
  end

  test "the Edge driver drives Edge with the Edge options" do
    options = ApplicationSystemTestCase.edge_options(binary: nil)

    ApplicationSystemTestCase.edge_driver(:app, driver_class: FakeDriver, options: options, service: nil)

    assert_equal({ browser: :edge, options: options }, FakeDriver.last.arguments)
    assert_equal :app, FakeDriver.last.app
  end

  test "the Edge driver opens a 1400 by 1400 window" do
    ApplicationSystemTestCase.edge_driver(:app, driver_class: FakeDriver)

    assert_equal Selenium::WebDriver::Dimension.new(1400, 1400), FakeDriver.last.window.dimension
  end

  test "Edge options run headless" do
    assert_includes ApplicationSystemTestCase.edge_options(binary: nil).args, "--headless"
  end

  test "Edge options disable the sandbox on CI" do
    args = ApplicationSystemTestCase.edge_options(binary: nil, ci: true).args

    assert_includes args, "--no-sandbox"
    assert_includes args, "--disable-dev-shm-usage"
  end

  test "Edge options skip first-run setup and the GPU on CI" do
    args = ApplicationSystemTestCase.edge_options(binary: nil, ci: true).args

    assert_includes args, "--no-first-run"
    assert_includes args, "--disable-gpu"
  end

  test "Edge options keep the sandbox off CI" do
    args = ApplicationSystemTestCase.edge_options(binary: nil, ci: false).args

    assert_not_includes args, "--no-sandbox"
    assert_not_includes args, "--disable-dev-shm-usage"
    assert_not_includes args, "--no-first-run"
    assert_not_includes args, "--disable-gpu"
  end

  test "log files are per process so parallel workers do not overwrite each other" do
    assert_equal Rails.root.join("tmp/screenshots/msedgedriver-42.log").to_s,
      ApplicationSystemTestCase.log_path("msedgedriver", pid: 42)
    first = ApplicationSystemTestCase.log_path("selenium", pid: 1)

    assert_not_equal first, ApplicationSystemTestCase.log_path("selenium", pid: 2)
  end

  test "the Edge service writes a verbose driver log into tmp/screenshots on CI" do
    service = ApplicationSystemTestCase.edge_service(ci: true)

    service.log # Selenium turns a String log path into a --log-path argument on first read.

    assert_includes service.args, "--log-path=#{ApplicationSystemTestCase.log_path("msedgedriver")}"
    assert_includes service.args, "--verbose"
  end

  test "there is no Edge service off CI" do
    assert_nil ApplicationSystemTestCase.edge_service(ci: false)
  end

  test "the Edge driver passes the Edge service to the driver" do
    service = Object.new

    ApplicationSystemTestCase.edge_driver(:app, driver_class: FakeDriver, service: service)

    assert_same service, FakeDriver.last.arguments[:service]
  end

  test "the Edge driver passes no service key without one" do
    ApplicationSystemTestCase.edge_driver(:app, driver_class: FakeDriver, service: nil)

    assert_not FakeDriver.last.arguments.key?(:service)
  end

  test "an explicit binary is used" do
    assert_equal "/opt/edge", ApplicationSystemTestCase.edge_options(binary: "/opt/edge").binary
  end

  test "without a binary Selenium Manager picks the installed Edge" do
    assert_nil ApplicationSystemTestCase.edge_options(binary: nil).binary
  end

  test "EDGE_BIN sets the Edge binary" do
    with_edge_bin("/opt/edge") { assert_equal "/opt/edge", ApplicationSystemTestCase.edge_options.binary }
    with_edge_bin("") { assert_nil ApplicationSystemTestCase.edge_options.binary }
  end

  test "the Chrome for Testing lookup is gone" do
    assert_not_respond_to ApplicationSystemTestCase, :chrome_binary
  end

  private
    def with_edge_bin(value)
      original = ENV["EDGE_BIN"]
      ENV["EDGE_BIN"] = value
      yield
    ensure
      ENV["EDGE_BIN"] = original
    end
end
