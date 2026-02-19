# frozen_string_literal: true

class AddSpansToFaultlineRequestTraces < ActiveRecord::Migration[8.1]
  def change
    add_column :faultline_request_traces, :spans, :json
    add_column :faultline_request_traces, :has_profile, :boolean, default: false
  end
end
