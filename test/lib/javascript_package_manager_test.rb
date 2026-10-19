require "test_helper"

class JavascriptPackageManagerTest < ActiveSupport::TestCase
  SELF = "test/lib/javascript_package_manager_test.rb".freeze
  DOC_PATHS = %w[docs/changes].freeze

  test "uses package-lock.json" do
    assert_predicate Rails.root.join("package-lock.json"), :file?
  end

  test "has no yarn lockfile" do
    assert_not Rails.root.join("yarn.lock").exist?
  end

  test "has no bin/yarn" do
    assert_not Rails.root.join("bin/yarn").exist?
  end

  test "bin/setup installs JavaScript packages with npm before preparing the database" do
    setup = Rails.root.join("bin/setup").read

    assert_operator setup.index('system!("npm install")'), :<, setup.index("bin/rails db:prepare")
  end

  test "names yarn nowhere outside data" do
    excluded = [ SELF, *DOC_PATHS ].map { |path| ":(exclude)#{path}" }
    hits = IO.popen([ "git", "grep", "-i", "-l", "yarn", "--", ".", *excluded ], chdir: Rails.root.to_s, &:read)

    assert_empty hits.split("\n")
  end
end
