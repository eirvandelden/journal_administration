require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  RUNNING_ENVIRONMENTS = %w[ development production ]
  SCHEMA_TASKS = %w[ db:migrate db:prepare ]
  MIGRATION_TASKS = %w[ data:migrate db:migrate:with_data ]

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
      assert_includes files_behind(schema_task), wiring_file,
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

    def wiring_file
      Rails.root.join("lib/tasks/data_migrate.rake").to_s
    end

    # Runs only the step this app appends to a schema task, with the data tasks it could reach
    # standing in for themselves, and reports which one it asked for.
    def data_tasks_run_by(schema_task)
      step = step_this_app_appends_to(schema_task)

      assert_not_nil step, "#{schema_task} should carry the step from #{wiring_file}"

      given_the_data_version_is_already_recorded
      asked_for = []
      standing_in = stand_in_for_the_migration_tasks(asked_for)

      step.call
      asked_for
    ensure
      standing_in&.each { |name, actions| put_back(name, actions) }
    end

    # Picked by where it comes from rather than by position: another gem enhancing a schema task
    # after this app would otherwise make the test call Rails' own action, which really migrates.
    def step_this_app_appends_to(schema_task)
      Rake::Task[schema_task].actions.find { |action| action.source_location&.first == wiring_file }
    end

    # The step also teaches a database with no data version the one on record. That is a different
    # behaviour from the one under test, so this test arrives at a database that already knows it.
    def given_the_data_version_is_already_recorded
      recorded = DataMigrate::RailsHelper.data_schema_migration
      recorded.create_table

      return unless DataMigrate::DataMigrator.current_version.zero?

      recorded.create_version(newest_data_migration)
    end

    def newest_data_migration
      Dir.children(Rails.root.join("db/data")).filter_map { |file| file[/\A\d+/] }.max
    end

    def stand_in_for_the_migration_tasks(asked_for)
      MIGRATION_TASKS.index_with { |name| Rake::Task[name].actions.dup }.each do |name, _actions|
        Rake::Task[name].actions.replace([ proc { asked_for << name } ])
        Rake::Task[name].reenable
      end
    end

    def put_back(task_name, actions)
      Rake::Task[task_name].actions.replace(actions)
      Rake::Task[task_name].reenable
    end
end
