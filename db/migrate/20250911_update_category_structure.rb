class UpdateCategoryStructure < ActiveRecord::Migration[6.0]
  def up
    Category.reset_column_information

    Category.find_each do |category|
      if category.name.include?(" - ")
        # This is a child category.
        parent_name = category.name.split(" - ").first
        parent_category = Category.find_by(name: parent_name)

        if parent_category
          # Assign the parent_category_id to the child category
          category.update(parent_category_id: parent_category.id)

          # Update the name to remove the parent category part
          new_name = category.name.sub("#{parent_name} - ", "")
          category.update(name: new_name)
        end
      end
    end
  end

  def down
      Category.reset_column_information

      Category.find_each do |category|
        if category.parent_category_id
          parent_name = category.name.split(" - ").first
          original_category = parent_name ? Category.find_by(name: parent_name) : nil

          if original_category
            # Restore the name to include the parent category and the original name
            original_name = "#{original_category.name} - #{category.name}"
            category.update(name: original_name, parent_category_id: nil)
          end
        end
      end
  end
end
