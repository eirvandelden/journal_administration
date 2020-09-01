class AddOriginalTagToTransaction < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :original_tag, :string
  end
end
