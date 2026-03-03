# frozen_string_literal: true

class ChangeSanitizedMessageToText < ActiveRecord::Migration[8.1]
  def up
    change_column :faultline_error_groups, :sanitized_message, :text, null: false
  end

  def down
    change_column :faultline_error_groups, :sanitized_message, :string, null: false
  end
end
