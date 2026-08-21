# Tells the assistant every category a transaction can be filed under
module Assistant
  class ListCategories < MCP::Tool
    description "List every category a transaction can be filed under, with the number that identifies it."
    annotations read_only_hint: true

    def self.call(server_context:)
      MCP::Tool::Response.new([ { type: "text", text: catalogue } ])
    end

    def self.catalogue
      Category.includes(:parent_category).map { |category| "#{category.id}: #{category.full_name}" }.join("\n")
    end
    private_class_method :catalogue
  end
end
