require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  RUNNING_ENVIRONMENTS = %w[ development production ]

  test "the cache, background jobs and live updates each get a database of their own" do
    RUNNING_ENVIRONMENTS.each do |environment|
      databases = databases_for(environment)

      assert_equal %w[ cable cache primary queue ], databases.map(&:name).sort,
        "#{environment} should keep the cache, jobs and live updates out of the main database"
      assert_equal databases.count, databases.map(&:database).uniq.count,
        "#{environment} points two connections at one file: #{databases.map(&:database).inspect}"
    end
  end

  test "live updates travel over the database rather than through a single process" do
    RUNNING_ENVIRONMENTS.each do |environment|
      live_updates = Rails.application.config_for(:cable, env: environment)

      assert_equal "solid_cable", live_updates[:adapter],
        "#{environment} should carry live updates over the database"
      assert_equal "cable", live_updates.dig(:connects_to, :database, :writing),
        "#{environment} should write live updates to the cable database"
    end
  end

  test "what the app remembers is kept in the cache database" do
    RUNNING_ENVIRONMENTS.each do |environment|
      assert_equal "cache", Rails.application.config_for(:cache, env: environment)[:database],
        "#{environment} should store the cache in the cache database"
    end
  end

  test "running the tests neither caches anything nor carries live updates" do
    assert_equal "test", Rails.application.config_for(:cable, env: "test")[:adapter]
    assert_nil Rails.application.config_for(:cache, env: "test")[:database]
    assert_equal %w[ primary ], databases_for("test").map(&:name)
  end

  private
    def databases_for(environment)
      ActiveRecord::Base.configurations.configs_for(env_name: environment)
    end
end
