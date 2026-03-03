module CategoriesHelper
  # Builds grouped options for category selection as specified:
  # - First, a nameless optgroup containing only parent categories (parent_category_id: nil)
  # - Then, for each parent (alphabetically), an optgroup labeled with the parent's name
  #   containing only that parent's children (alphabetically) with labels as the child name
  # Returns an HTML-safe string suitable for use in f.select grouped options.
  def grouped_category_options(selected: nil)
    parents = Category.groups.includes(:secondaries).order(Arel.sql('LOWER(name) ASC'))

    groups = []

    # First nameless group with parent categories
    parent_options = parents.map { |p| [ p.name, p.id ] }
    groups << [ "", parent_options ] if parent_options.any?

    # Then one group per parent with its children
    parents.each do |parent|
      children = parent.secondaries.sort_by { |c| c.name.downcase }
      next if children.empty?

      child_options = children.map { |c| [ c.name, c.id ] }
      groups << [ parent.name, child_options ]
    end

    grouped_options_for_select(groups, selected)
  end
end
