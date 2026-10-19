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

    ApplicationSystemTestCase.edge_driver(:app, driver_class: FakeDriver, options: options)

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
