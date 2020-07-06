class AddOriginalNoteToTransactions < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :original_note, :text
  end
end
