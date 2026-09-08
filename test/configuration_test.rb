require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  RUNNING_ENVIRONMENTS = %w[ development production ]
  SCHEMA_TASKS = %w[ db:migrate db:prepare ]
  DATA_TASKS = %w[ data:migrate db:migrate:with_data ]

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

  test "migrating the schema also migrates the data" do
    load_rake_tasks

    SCHEMA_TASKS.each do |schema_task|
      assert_includes files_behind(schema_task), Rails.root.join("lib/tasks/data_migrate.rake").to_s,
        "#{schema_task} should run the data migrations too, or a backfill never happens on deploy"
    end
  end

  test "the data migrations run through the task that writes the schema file afterwards" do
    load_rake_tasks

    SCHEMA_TASKS.each do |schema_task|
      assert_equal [ "db:migrate:with_data" ], data_tasks_run_by(schema_task),
        "#{schema_task} should leave the schema file describing a database the data migrations have run on"
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

    def load_rake_tasks
      require "rake"
      Rails.application.load_tasks unless Rake::Task.task_defined?("db:migrate")
    end

    def files_behind(task_name)
      Rake::Task[task_name].actions.filter_map { |action| action.source_location&.first }
    end

    # Runs only the step this app appends to a schema task, with the data tasks it could reach
    # standing in for themselves, and reports which one it asked for.
    def data_tasks_run_by(schema_task)
      asked_for = []
      standing_in = DATA_TASKS.index_with { |name| Rake::Task[name].actions.dup }

      standing_in.each_key do |name|
        Rake::Task[name].actions.replace([ proc { asked_for << name } ])
        Rake::Task[name].reenable
      end

      Rake::Task[schema_task].actions.last.call
      asked_for
    ensure
      standing_in.each { |name, actions| Rake::Task[name].actions.replace(actions) }
    end
end
