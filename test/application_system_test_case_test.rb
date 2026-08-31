require "test_helper"
require "application_system_test_case"
require "tmpdir"

class ApplicationSystemTestCaseTest < ActiveSupport::TestCase
  test "the newest cached browser is used when one is available" do
    Dir.mktmpdir do |cache_root|
      make_cached_chrome(cache_root, "150.0.7871.24")
      newest = make_cached_chrome(cache_root, "152.0.7977.64")

      assert_equal newest, ApplicationSystemTestCase.chrome_binary(cache_root: cache_root)
    end
  end

  test "no browser is found when the cache holds no browser binary" do
    Dir.mktmpdir do |cache_root|
      assert_nil ApplicationSystemTestCase.chrome_binary(cache_root: cache_root)
    end
  end

  test "a non-version directory in the cache does not stop the search" do
    Dir.mktmpdir do |cache_root|
      FileUtils.mkdir_p(File.join(cache_root, "mac-arm64", "partial-download"))
      only_valid = make_cached_chrome(cache_root, "152.0.7977.64")

      assert_equal only_valid, ApplicationSystemTestCase.chrome_binary(cache_root: cache_root)
    end
  end

  private

  def make_cached_chrome(cache_root, version)
    leaf = File.join(cache_root, "mac-arm64", version, "Google Chrome for Testing.app/Contents/MacOS")
    FileUtils.mkdir_p(leaf)
    binary = File.join(leaf, "Google Chrome for Testing")
    FileUtils.touch(binary)
    File.chmod(0755, binary)
    binary
  end
end
