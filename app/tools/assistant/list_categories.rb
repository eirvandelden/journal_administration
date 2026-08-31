# Tells the assistant every category a transaction can be filed under
module Assistant
  class ListCategories < Tool
    HIGHEST_COUNT = 250

    description "List every category a transaction can be filed under, with the number that identifies it. " \
      "At most #{HIGHEST_COUNT} are listed."
    annotations read_only_hint: true

    def self.call(server_context:)
      categories = Category.includes(:parent_category).limit(HIGHEST_COUNT)

      answer([ *categories.map { |category| describe(category) }, held_back(categories) ].compact.join("\n"))
    end

    def self.describe(category)
      "#{category.id}: #{category.full_name}"
    end
    private_class_method :describe

    # An assistant reading a list it believes is complete files transactions under the wrong
    # category rather than asking, so a shortened list has to say so.
    def self.held_back(categories)
      total = Category.count

      return nil if total <= categories.length

      "Showing #{categories.length} of #{total} categories - the rest are on the categories page."
    end
    private_class_method :held_back
  end
end
