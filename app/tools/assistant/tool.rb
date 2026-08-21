# Common ground for everything an assistant may do to the books
module Assistant
  class Tool < MCP::Tool
    def self.answer(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ])
    end
    private_class_method :answer

    def self.problem(message)
      MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
    end
    private_class_method :problem
  end
end
