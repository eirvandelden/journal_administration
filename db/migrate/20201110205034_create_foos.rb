class CreateFoos < ActiveRecord::Migration[6.0]
  def change
    create_table :foos do |t|
      t.integer :foo_id, null: false
      t.integer :bar_id, null: false # will lead to belonsg_to :transaction, which is a keyword
    end
  end
end
