# Lets an assistant add a category for groceries nothing existing fits, under Huishoudelijke uitgaven
module Assistant
  class CreateHouseholdCategory < Tool
    description "Find or create a category under #{Category::HOUSEHOLD_EXPENSES}, for groceries no " \
      "existing category fits. It is created with the same direction as its group. A category cannot be " \
      "created anywhere else."
    annotations idempotent_hint: true
    input_schema(
      properties: { name: { type: "string", description: "The name of the category" } },
      required: [ "name" ]
    )

    def self.call(name:, server_context:)
      return problem("A category needs a name.") if name.blank?

      category = Category.add_household_expense(name)

      answer("Category ##{category.id} #{category.full_name} is ready to use.")
    rescue ActiveRecord::RecordNotFound
      problem("The group #{Category::HOUSEHOLD_EXPENSES} does not exist, so no category was created.")
    end
  end
end
