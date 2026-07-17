class DropFaultlineTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :faultline_request_profiles, if_exists: true
    drop_table :faultline_request_traces, if_exists: true
    drop_table :faultline_error_contexts, if_exists: true
    drop_table :faultline_error_occurrences, if_exists: true
    drop_table :faultline_error_groups, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
