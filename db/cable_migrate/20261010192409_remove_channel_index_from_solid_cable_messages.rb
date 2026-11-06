class RemoveChannelIndexFromSolidCableMessages < ActiveRecord::Migration[8.1]
  #: () -> void
  def up
    remove_index :solid_cable_messages, :channel, if_exists: true
  end

  #: () -> void
  def down
    add_index :solid_cable_messages, :channel, if_not_exists: true
  end
end
