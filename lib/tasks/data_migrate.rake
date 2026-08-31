# Data migrations nobody runs are worse than none: a backfill silently never happens. The gem
# adds `db:migrate:with_data` but leaves the ordinary tasks alone, so deploys (`bin/start-app`
# runs `db:prepare`) and everyday `db:migrate` both skip them. Both are taught to run them here,
# rather than in every script that migrates.
#
# A database built from `db/schema.rb` has recorded the schema version but no data version, so it
# would replay fixes to data that no longer exists — and some of those cannot run against an empty
# database. Such a database adopts the recorded data version first, the way loading the schema
# adopts the recorded schema version.
%w[ db:migrate db:prepare ].each do |schema_task|
  Rake::Task[schema_task].enhance do
    load Rails.root.join("db/data_schema.rb") if DataMigrate::DataMigrator.current_version.zero?

    Rake::Task["data:migrate"].invoke
  end
end
