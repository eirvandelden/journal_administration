require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  OLD_CHROME_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
  ELECTRON_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) ResponsivelyApp/1.9.0 Chrome/108.0.0.0 Electron/13.0.0 Safari/537.36"

  class InLocalEnvironment < ActionDispatch::IntegrationTest
    setup do
      sign_in_as users(:admin)
    end

    test "Electron UA is allowed through" do
      get root_url, headers: { "HTTP_USER_AGENT" => ELECTRON_UA }
      assert_not_equal 406, response.status
    end

    test "old Chrome UA without Electron is blocked with 406" do
      get root_url, headers: { "HTTP_USER_AGENT" => OLD_CHROME_UA }
      assert_response :not_acceptable
    end
  end
end
