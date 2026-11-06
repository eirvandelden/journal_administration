class SetDirectionForCategories < ActiveRecord::Migration[6.0]
  #: () -> void
  def up
    Category.all.each do |category|
      category.name.include?("Inkomsten") ? category.update(direction: :debit) : category.update(direction: :credit)
    end
  end

  #: () -> void
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
