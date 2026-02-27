module CategoriesHelper
  # Builds grouped options for category selection.
  #
  # The first optgroup (without a label) contains parent categories. Each
  # following optgroup contains the children of one parent category.
  #
  # @param selected [Integer, String, nil] The selected category id
  # @return [ActiveSupport::SafeBuffer]
  def grouped_category_options(selected: nil)
    grouped_options_for_select(category_option_groups, selected)
  end

  private

  def category_option_groups
    parents = sorted_parent_categories
    [ parent_category_group(parents), *child_category_groups(parents) ].compact
  end

  def sorted_parent_categories
    Category.groups.includes(:secondaries).order(Arel.sql("LOWER(name) ASC"))
  end

  def parent_category_group(parents)
    parent_options = parents.map { |parent| [ parent.name, parent.id ] }
    return if parent_options.empty?

    [ "", parent_options ]
  end

  def child_category_groups(parents)
    parents.filter_map do |parent|
      child_options = sorted_child_options(parent)
      next if child_options.empty?

      [ parent.name, child_options ]
    end
  end

  def sorted_child_options(parent)
    parent.secondaries.sort_by { |child| child.name.downcase }.map { |child| [ child.name, child.id ] }
  end
end
